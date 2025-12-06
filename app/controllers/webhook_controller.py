from flask import Blueprint, request, jsonify
from app.models.user import UserModel
from app.models.review import ReviewModel
from app.services.sentiment_service import clean_text, analyze_sentiment, analyze_toxicity, classify_review, detect_review_quality
from app.services.deepseek_service import (
    organize_customer_feedback,
    determine_overall_sentiment,
    generate_actionable_insights,
    generate_suggested_reply
)
from app.services.notification_service import send_fcm_notification, send_telegram_notification
from bson import ObjectId
import logging

webhook_bp = Blueprint('webhook', __name__)
user_model = UserModel()
review_model = ReviewModel()

@webhook_bp.route('/webhook', methods=['POST'])
def webhook():
    try:
        data = request.json
        if not data or not data.get('fields'):
            logging.warning("Invalid webhook data received")
            return jsonify({"error": "Invalid data"}), 400

        fields = data['fields']
        email = fields.get('email', '').strip().lower()
        text = fields.get('text', '').strip()
        shop_id = fields.get('shop_id', '').strip()
        stars = int(fields.get('stars', 0)) if fields.get('stars') else 0

        enjoy_most = fields.get('enjoy_most', '').strip()
        improve_product = fields.get('improve_product', '').strip()
        additional_feedback = fields.get('additional_feedback', '').strip()

        if not email or not text or not shop_id:
            logging.warning(f"Missing required fields: email={bool(email)}, text={bool(text)}, shop_id={bool(shop_id)}")
            return jsonify({"error": "Missing required fields: email, text, shop_id"}), 400

        existing_review = review_model.find_existing_review(email, shop_id)
        if existing_review:
            logging.warning(f"Duplicate review attempt from {email} for shop {shop_id}")
            return jsonify({"error": "لقد قمت بإرسال تقييم لهذا المتجر مسبقاً"}), 400

        owner = user_model.find_by_id(shop_id)
        shop_type = owner.get('shop_type', 'عام') if owner else 'عام'

        cleaned_text = clean_text(text)
        sentiment = analyze_sentiment(cleaned_text)
        toxicity = analyze_toxicity(cleaned_text)
        review_type = classify_review(sentiment, toxicity)

        overall_sentiment = determine_overall_sentiment(stars, text, improve_product, additional_feedback)

        quality_check = detect_review_quality(text, enjoy_most, improve_product, additional_feedback)
        if quality_check['is_suspicious']:
            logging.warning(f"Suspicious review detected from {email}: quality_score={quality_check['quality_score']}, flags={quality_check['flags']}")

        organized_feedback = organize_customer_feedback(enjoy_most, improve_product, additional_feedback)

        # Generate actionable insights and suggested reply using DeepSeek
        actionable_insights = ""
        suggested_reply = ""

        try:
            if overall_sentiment == "سلبي" or review_type in ['شكوى', 'نقد']:
                actionable_insights = generate_actionable_insights(text, improve_product, shop_type)

            suggested_reply = generate_suggested_reply(text, overall_sentiment, shop_type)
        except Exception as e:
            logging.error(f"DeepSeek generation failed: {e}")

        # Fallback for solutions if AI fails or returns empty
        solutions = actionable_insights if actionable_insights else ""
        if not solutions and (overall_sentiment == "سلبي" or review_type in ['شكوى', 'نقد']):
            solutions = f"بناءً على التقييم السلبي والاقتراحات المقدمة، يُنصح بمراجعة النقاط المذكورة في اقتراحات التحسين."

        review_data = {
            "email": email,
            "shop_id": shop_id,
            "stars": stars,
            "overall_sentiment": overall_sentiment,
            "organized_feedback": organized_feedback,
            "solutions": solutions,
            "suggested_reply": suggested_reply,
            "original_fields": {
                "text": text,
                "enjoy_most": enjoy_most,
                "improve_product": improve_product,
                "additional_feedback": additional_feedback
            },
            "technical_analysis": {
                "cleaned_text": cleaned_text,
                "sentiment": sentiment,
                "toxicity": toxicity,
                "review_type": review_type,
                "shop_type": shop_type
            }
        }

        review_id = review_model.create_review(review_data)
        logging.info(f"Review saved: {review_id}")

        try:
            if owner:
                message = f"تقييم جديد: {'⭐' * stars}\n\"{text}\"\nالنوع: {review_type}"
                if solutions:
                    message += f"\n\n💡 الحل المقترح:\n{solutions}"

                if owner.get('device_token'):
                    send_fcm_notification(owner['device_token'], message)
                elif owner.get('telegram_chat_id'):
                    send_telegram_notification(owner['telegram_chat_id'], message)
        except Exception as e:
            logging.error(f"Notification failed: {e}")

        return jsonify({"status": "success", "review_id": review_id}), 200

    except Exception as e:
        logging.error(f"Webhook error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500
