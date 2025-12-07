from flask import Blueprint, request
from app.services.core.webhook_service import WebhookService
from app.utils.response import ResponseBuilder
from app.dto.review_dto import ReviewDTO
import logging

webhook_bp = Blueprint('webhook', __name__)
webhook_service = WebhookService()

@webhook_bp.route('/webhook', methods=['POST'])
def webhook():
    try:
        data = request.json or {}
        dto = ReviewDTO.from_dict(data)

        result = webhook_service.process_review(dto)
        return ResponseBuilder.success(result, "تم حفظ التقييم بنجاح", 200)

    except ValueError as e:
        logging.warning(f"Validation error: {e}")
        return ResponseBuilder.error(str(e), 400)
    except LookupError as e:
        logging.warning(f"Duplicate or not found: {e}")
        return ResponseBuilder.error(str(e), 400)
    except Exception as e:
        logging.error(f"Webhook error: {e}", exc_info=True)
        return ResponseBuilder.error("Internal server error", 500)