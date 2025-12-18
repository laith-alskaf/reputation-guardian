"""
Webhook Service Package - Refactored webhook processing components.

This package contains a refactored implementation following Clean Architecture
and SOLID principles. The original monolithic WebhookService has been split into:

- extractors: Form field extraction
- validators: Data validation
- processors: Review processing (quality, relevancy, AI analysis)
- handlers: Notification and Telegram interactions
- use_cases: Orchestration logic

The main WebhookService acts as a lightweight facade.
"""
from app.application.services.webhook.extractors import FormFieldExtractor
from app.application.services.webhook.validators import ShopValidator, ReviewValidator
from app.application.services.webhook.processors import (
    QualityGateProcessor,
    RelevancyGateProcessor,
    AIAnalysisProcessor
)
from app.application.services.webhook.handlers import NotificationHandler, TelegramHandler
from app.application.services.webhook.use_cases import ProcessReviewUseCase, ProcessTelegramUseCase

__all__ = [
    'FormFieldExtractor',
    'ShopValidator',
    'ReviewValidator',
    'QualityGateProcessor',
    'RelevancyGateProcessor',
    'AIAnalysisProcessor',
    'NotificationHandler',
    'TelegramHandler',
    'ProcessReviewUseCase',
    'ProcessTelegramUseCase',
]

