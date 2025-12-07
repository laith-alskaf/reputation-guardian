import logging
from app.models.user import UserModel
from app.models.review import ReviewModel
from app.services.external import SentimentService, DeepSeekService, NotificationService
from app.services_interfaces import IWebhookService
class WebhookService(IWebhookService):
    def __init__(self):
        self.user_model = UserModel()
        self.review_model = ReviewModel()
        self.deepseek_service = DeepSeekService()
        self.notification_service = NotificationService()

    def process_review(self, dto):
        if not dto.email or not dto.text or not dto.shop_id:
            raise ValueError("Missing required fields: email, text, shop_id")

        existing_review = self.review_model.find_existing_review(dto.email, dto.shop_id)
        if existing_review:
            raise LookupError("لقد قمت بإرسال تقييم لهذا المتجر مسبقاً")

        owner = self.user_model.find_by_id(dto.shop_id)
        shop_type = owner.get('shop_type', 'عام') if owner else 'عام'

        # تحليل النص
        cleaned_text = SentimentService.clean_text(dto.text)
        sentiment = SentimentService.analyze_sentiment(cleaned_text)
        toxicity = SentimentService.analyze_toxicity(cleaned_text)
        review_type = SentimentService.classify_review(sentiment, toxicity)

        # fallback للنجوم إذا النتيجة محايدة
        if sentiment == "محايد":
            if dto.stars <= 2:
                sentiment = "سلبي"
            elif dto.stars >= 4:
                sentiment = "إيجابي"

        overall_sentiment = self.deepseek_service.determine_overall_sentiment(
            dto.stars, dto.text, dto.improve_product, dto.additional_feedback
        )

        quality_check = SentimentService.detect_review_quality(
            dto.text, dto.enjoy_most, dto.improve_product, dto.additional_feedback
        )
        if quality_check['is_suspicious']:
            logging.warning(f"Suspicious review detected from {dto.email}: quality_score={quality_check['quality_score']}, flags={quality_check['flags']}")

        organized_feedback = self.deepseek_service.organize_customer_feedback(
            dto.enjoy_most, dto.improve_product, dto.additional_feedback
        )

        actionable_insights = ""
        suggested_reply = ""
        try:
            if overall_sentiment == "سلبي" or review_type in ['شكوى', 'نقد']:
                actionable_insights = self.deepseek_service.generate_actionable_insights(dto.text, dto.improve_product, shop_type)

            suggested_reply = self.deepseek_service.generate_suggested_reply(dto.text, overall_sentiment, shop_type)
        except Exception as e:
            logging.error(f"DeepSeek generation failed: {e}")

        solutions = actionable_insights if actionable_insights else ""
        if not solutions and (overall_sentiment == "سلبي" or review_type in ['شكوى', 'نقد']):
            solutions = "بناءً على التقييم السلبي والاقتراحات المقدمة، يُنصح بمراجعة النقاط المذكورة في اقتراحات التحسين."

        review_data = {
            "email": dto.email,
            "shop_id": dto.shop_id,
            "stars": dto.stars,
            "overall_sentiment": overall_sentiment,
            "organized_feedback": organized_feedback,
            "solutions": solutions,
            "suggested_reply": suggested_reply,
            "original_fields": {
                "text": dto.text,
                "enjoy_most": dto.enjoy_most,
                "improve_product": dto.improve_product,
                "additional_feedback": dto.additional_feedback
            },
            "technical_analysis": {
                "cleaned_text": cleaned_text,
                "sentiment": sentiment,
                "toxicity": toxicity,
                "review_type": review_type,
                "shop_type": shop_type
            }
        }

        review_id = self.review_model.create_review(review_data)
        logging.info(f"Review saved: {review_id}")

        if owner:
            message = f"تقييم جديد: {'⭐' * dto.stars}\n\"{dto.text}\"\nالنوع: {review_type}"
            if solutions:
                message += f"\n\n💡 الحل المقترح:\n{solutions}"

            try:
                if owner.get('device_token'):
                    self.notification_service.send_fcm_notification(owner['device_token'], message)
                elif owner.get('telegram_chat_id'):
                    self.notification_service.send_telegram_notification(owner['telegram_chat_id'], message)
                else:
                    logging.warning(f"No notification channel found for shop owner {dto.shop_id}")
            except Exception as e:
                logging.error(f"Notification failed: {e}")

        return {"review_id": review_id}