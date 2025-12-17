"""Webhook routes."""
from flask import Blueprint, request, jsonify
from app.application.services import WebhookService
from app.presentation.utils.response import ResponseBuilder
from app.application.dto.review_dto import ReviewDTO
from app.presentation.config import SIGNING_SECRET
import logging
import hmac
import hashlib
import base64

webhook_bp = Blueprint('webhook', __name__)
webhook_service = WebhookService()


@webhook_bp.route('/webhook', methods=['POST'])
def webhook():
    # Verify Signature
    # if SIGNING_SECRET:
    #     signature = request.headers.get('Tally-Signature')
    #     if not signature:
    #          return ResponseBuilder.error("Missing Tally-Signature header", 401)
        
    #     # Calculate expected signature
    #     payload = request.get_data()
    #     calculated_signature = base64.b64encode(
    #         hmac.new(SIGNING_SECRET.encode('utf-8'), payload, hashlib.sha256).digest()
    #     ).decode('utf-8')
        
    #     if not hmac.compare_digest(signature, calculated_signature):
    #          return ResponseBuilder.error("Invalid Signature", 403)

    try:
        data = request.json or {}

        # The service layer now handles the raw dictionary directly.
        result = webhook_service.process_review(data)
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


@webhook_bp.route('/webhook/telegram', methods=['POST'])
def telegram_webhook():
    """Endpoint for Telegram Webhook"""
    try:
        data = request.json or {}
        webhook_service.process_telegram_webhook(data)
        return ResponseBuilder.success(None, "OK", 200)
    except Exception as e:
        logging.error(f"Telegram Webhook error: {e}", exc_info=True)
        return ResponseBuilder.error("Internal server error", 500)
