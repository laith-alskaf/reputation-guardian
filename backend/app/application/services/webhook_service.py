"""
Webhook Service - Refactored
Main service facade for webhook processing.

This service has been refactored following Clean Architecture and SOLID principles.
It now acts as a lightweight orchestrator delegating to specialized use cases.
"""
import logging
from typing import Dict, Any

from app.infrastructure.repositories import UserRepository, ReviewRepository
from app.infrastructure.external import (
    SentimentService,
    DeepSeekService,
    NotificationService,
    TelegramService,
    QualityService
)

# Import all components
from app.application.services.webhook.extractors.form_field_extractor import FormFieldExtractor
from app.application.services.webhook.validators.shop_validator import ShopValidator
from app.application.services.webhook.validators.review_validator import ReviewValidator
from app.application.services.webhook.processors.quality_gate_processor import QualityGateProcessor
from app.application.services.webhook.processors.relevancy_gate_processor import RelevancyGateProcessor
from app.application.services.webhook.processors.ai_analysis_processor import AIAnalysisProcessor
from app.application.services.webhook.handlers.notification_handler import NotificationHandler
from app.application.services.webhook.handlers.telegram_handler import TelegramHandler
from app.application.services.webhook.use_cases.process_review_use_case import ProcessReviewUseCase
from app.application.services.webhook.use_cases.process_telegram_use_case import ProcessTelegramUseCase


class WebhookService:
    """
    Main webhook service - Acts as a facade/orchestrator.
    
    Responsibilities:
    - Initialize all dependencies and components
    - Provide public API for webhook processing
    - Delegate to appropriate use cases
    
    Benefits of refactoring:
    - Each component has a single, clear responsibility (SRP)
    - Easy to test individual components in isolation
    - Easy to extend with new processors or validators (OCP)
    - Dependencies are injected and easily mockable (DIP)
    """
    
    def __init__(
        self,
        user_repository: UserRepository = None,
        review_repository: ReviewRepository = None,
        telegram_service: TelegramService = None
    ):
        """
        Initialize WebhookService with dependency injection.
        
        Constructs all required components and use cases.
        
        Args:
            user_repository: Optional repository for user/shop data
            review_repository: Optional repository for review data
            telegram_service: Optional Telegram service instance
        """
        # Initialize repositories
        self.user_repository = user_repository or UserRepository()
        self.review_repository = review_repository or ReviewRepository()
        
        # Initialize external services
        self.sentiment_service = SentimentService()
        self.deepseek_service = DeepSeekService()
        self.notification_service = NotificationService()
        self.telegram_service = telegram_service or TelegramService(self.notification_service)
        self.quality_service = QualityService()
        
        # Initialize components
        self._initialize_components()
        
        # Initialize use cases
        self._initialize_use_cases()
    
    def _initialize_components(self):
        """Initialize all service components."""
        # Extractors
        self.form_extractor = FormFieldExtractor()
        
        # Validators
        self.shop_validator = ShopValidator(self.user_repository)
        self.review_validator = ReviewValidator(self.review_repository)
        
        # Processors
        self.quality_processor = QualityGateProcessor(self.quality_service)
        self.relevancy_processor = RelevancyGateProcessor(self.sentiment_service)
        self.ai_processor = AIAnalysisProcessor(
            self.sentiment_service,
            self.deepseek_service
        )
        
        # Handlers
        self.notification_handler = NotificationHandler(
            self.notification_service,
            self.telegram_service
        )
        self.telegram_handler = TelegramHandler(
            self.user_repository,
            self.telegram_service
        )
    
    def _initialize_use_cases(self):
        """Initialize use cases with all required dependencies."""
        self.process_review_use_case = ProcessReviewUseCase(
            form_extractor=self.form_extractor,
            shop_validator=self.shop_validator,
            review_validator=self.review_validator,
            quality_processor=self.quality_processor,
            relevancy_processor=self.relevancy_processor,
            ai_processor=self.ai_processor,
            notification_handler=self.notification_handler,
            review_repository=self.review_repository,
            sentiment_service=self.sentiment_service
        )
        
        self.process_telegram_use_case = ProcessTelegramUseCase(
            telegram_handler=self.telegram_handler
        )
    
    def process_review(self, form_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process a new review from a webhook.
        
        Applies sequential quality and relevancy gates before committing
        to expensive AI analysis. This is the main public API method.
        
        Args:
            form_data: Webhook payload containing review data
            
        Returns:
            Dictionary with processing result:
            - status: 'processed', 'rejected_low_quality', or 'rejected_irrelevant'
            - review_id: ID of saved review (if processed)
            - reason: Rejection reason (if rejected)
            
        Raises:
            ValueError: If payload is invalid or missing required fields
            LookupError: If shop not found or duplicate review exists
        """
        return self.process_review_use_case.execute(form_data)
    
    def process_telegram_webhook(self, update_data: Dict[str, Any]):
        """
        Process Telegram webhook updates.
        
        Handles Telegram bot commands and user interactions.
        
        Args:
            update_data: Telegram webhook update payload
        """
        self.process_telegram_use_case.execute(update_data)
