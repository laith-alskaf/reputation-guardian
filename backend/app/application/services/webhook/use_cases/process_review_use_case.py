"""
Process Review Use Case
Orchestrates the complete review processing flow.
"""
import logging
from typing import Dict, Any
from bson import ObjectId

from app.infrastructure.external import SentimentService
from app.application.dto.review_processing_dto import ReviewDocument, Source, Processing
from app.application.services.webhook.extractors.form_field_extractor import FormFieldExtractor
from app.application.services.webhook.validators.shop_validator import ShopValidator
from app.application.services.webhook.validators.review_validator import ReviewValidator
from app.application.services.webhook.processors.quality_gate_processor import QualityGateProcessor
from app.application.services.webhook.processors.relevancy_gate_processor import RelevancyGateProcessor
from app.application.services.webhook.processors.ai_analysis_processor import AIAnalysisProcessor
from app.application.services.webhook.handlers.notification_handler import NotificationHandler
from app.infrastructure.repositories import ReviewRepository


class ProcessReviewUseCase:
    """
    Use case for processing review webhooks.
    
    Orchestrates the complete flow:
    1. Extract form fields
    2. Validate shop and review data
    3. Prepare initial data
    4. Calculate toxicity (once)
    5. Run quality gate
    6. Run relevancy gate (if needed)
    7. Perform AI analysis (if needed)
    8. Assemble and save document
    9. Send notification
    
    Follows clean architecture principles with dependency injection.
    """
    
    def __init__(
        self,
        form_extractor: FormFieldExtractor,
        shop_validator: ShopValidator,
        review_validator: ReviewValidator,
        quality_processor: QualityGateProcessor,
        relevancy_processor: RelevancyGateProcessor,
        ai_processor: AIAnalysisProcessor,
        notification_handler: NotificationHandler,
        review_repository: ReviewRepository,
        sentiment_service: SentimentService
    ):
        """
        Initialize use case with all required dependencies.
        
        Args:
            form_extractor: Extracts form fields from payload
            shop_validator: Validates shop existence
            review_validator: Validates review data
            quality_processor: Processes quality gate
            relevancy_processor: Processes relevancy gate
            ai_processor: Processes AI analysis
            notification_handler: Sends notifications
            review_repository: Repository for review persistence
            sentiment_service: Service for text cleaning and toxicity
        """
        self.form_extractor = form_extractor
        self.shop_validator = shop_validator
        self.review_validator = review_validator
        self.quality_processor = quality_processor
        self.relevancy_processor = relevancy_processor
        self.ai_processor = ai_processor
        self.notification_handler = notification_handler
        self.review_repository = review_repository
        self.sentiment_service = sentiment_service
    
    def execute(self, form_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute the review processing use case.
        
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
        # --- Step 1: Extract Form Fields ---
        fields = form_data.get('data', {}).get('fields', [])
        if not fields:
            raise ValueError("Payload is missing 'data.fields' array.")
        
        extracted_fields = self.form_extractor.extract(fields)
        logging.info(f"Extracted fields for shop {extracted_fields.get('shop_id')}")
        
        # --- Step 2: Validate Shop ---
        shop_id = extracted_fields.get('shop_id')
        shop_validation, owner = self.shop_validator.validate_and_get_shop(shop_id)
        
        if not shop_validation.is_valid:
            raise LookupError(shop_validation.error_message)
        
        # --- Step 3: Validate Review (Check Duplicates) ---
        respondent_email = extracted_fields.get('respondent_email')
        if respondent_email:
            duplicate_check = self.review_validator.check_duplicate_review(respondent_email, shop_id)
            if not duplicate_check.is_valid:
                raise LookupError(duplicate_check.error_message)
        
        # --- Step 4: Prepare Initial Data ---
        source, processing = self._prepare_initial_data(extracted_fields)
        
        # --- Step 5: Pre-calculate Toxicity (once for entire flow) ---
        toxicity_status = self.sentiment_service.analyze_toxicity(processing.concatenated_text)
        
        # --- Step 6: Quality Gate (Gate 1) ---
        passes_quality, quality_result = self.quality_processor.assess_quality(
            extracted_fields,
            toxicity_status
        )
        
        if not passes_quality:
            rejected_doc = self.quality_processor.create_rejected_quality_document(
                shop_id=shop_id,
                email=respondent_email,
                rating=source.rating,
                source=source,
                processing=processing,
                quality_result=quality_result
            )
            self.review_repository.create_review(rejected_doc.model_dump(by_alias=True))
            logging.warning(f"Rejected low-quality review for shop {shop_id}")
            return {"status": "rejected_low_quality", "reason": "Review did not meet quality standards."}
        
        logging.info(f"Review for shop {shop_id} passed Quality Gate.")
        
        # --- Step 7: Relevancy Gate (Gate 2) ---
        shop_type = extracted_fields.get('shop_type', 'عام')
        quality_flags = quality_result.get('flags', [])
        
        is_relevant, context_result = self.relevancy_processor.check_relevancy(
            processing.concatenated_text,
            shop_type,
            quality_flags
        )
        
        if not is_relevant:
            rejected_doc = self.relevancy_processor.create_rejected_relevancy_document(
                shop_id=shop_id,
                email=respondent_email,
                rating=source.rating,
                source=source,
                processing=processing,
                quality_result=quality_result,
                context_result=context_result
            )
            self.review_repository.create_review(rejected_doc.model_dump(by_alias=True))
            logging.warning(f"Rejected irrelevant review for shop {shop_id}")
            return {"status": "rejected_irrelevant", "reason": "Review content is not relevant to the shop category."}
        
        logging.info(f"Review for shop {shop_id} passed Relevancy Gate.")
        
        # --- Step 8: Full AI Analysis (for High-Quality, Relevant Reviews) ---
        logging.info(f"Proceeding with full analysis for shop {shop_id}.")
        
        source_fields = extracted_fields.get('source_fields', {})
        analysis_result = self.ai_processor.analyze(
            text=processing.concatenated_text,
            rating=source.rating,
            source_fields=source_fields,
            shop_type=shop_type,
            quality_result=quality_result
        )
        
        # --- Step 9: Final Document Assembly & Saving ---
        processed_doc = ReviewDocument(
            id=str(ObjectId()),
            shop_id=shop_id,
            email=respondent_email,
            stars=source.rating,
            overall_sentiment=analysis_result['sentiment'],
            status="processed",
            source=source,
            processing=processing,
            analysis={
                "sentiment": analysis_result['sentiment'],
                "toxicity": analysis_result['toxicity'],
                "category": analysis_result['category'],
                "quality": quality_result,
                "context": context_result,
                "key_themes": analysis_result['key_themes'],
            },
            generated_content=analysis_result['generated_content']
        )
        
        review_id = self.review_repository.create_review(processed_doc.model_dump(by_alias=True))
        logging.info(f"Successfully processed and saved review {review_id} for shop {shop_id}.")
        
        # --- Step 10: Send Notification ---
        if owner and (owner.device_token or owner.telegram_chat_id):
            self.notification_handler.send_review_notification(owner, processed_doc)
        
        return {"status": "processed", "review_id": str(review_id)}
    
    def _prepare_initial_data(self, extracted_fields: Dict[str, Any]) -> tuple:
        """
        Prepare Source and Processing objects from extracted fields.
        
        Args:
            extracted_fields: Dictionary of extracted form data
            
        Returns:
            Tuple of (Source, Processing) objects
        """
        source_obj = Source(
            rating=extracted_fields.get('rating', 0),
            fields=extracted_fields.get('source_fields', {})
        )
        
        # Extract and concatenate the three text fields
        source_fields = extracted_fields.get('source_fields', {})
        text_parts = []
        
        for field_name in ['enjoy_most', 'improve_product', 'additional_feedback']:
            field_value = source_fields.get(field_name, '')
            if field_value and isinstance(field_value, str) and field_value.strip():
                text_parts.append(field_value.strip())
        
        concatenated_text = " ".join(text_parts)
        
        # Clean text (toxicity will be calculated in main flow)
        cleaned_text = SentimentService.clean_text(concatenated_text)
        
        processing_obj = Processing(
            concatenated_text=cleaned_text,
            is_profane=False  # Will be determined by toxicity analysis
        )
        
        return source_obj, processing_obj
