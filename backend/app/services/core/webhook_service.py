import logging
from app.models.user import UserModel
from app.models.review import ReviewModel
from app.services.external import SentimentService, DeepSeekService, NotificationService
from app.services_interfaces import IWebhookService
from app.dto.analysis_result_dto import AnalysisResultDTO

class WebhookService(IWebhookService):
    def __init__(self):
        self.user_model = UserModel()
        self.review_model = ReviewModel()
        self.deepseek_service = DeepSeekService()
        self.notification_service = NotificationService()

    def process_review(self, dto):
        if not dto.email or not dto.shop_id or not dto.shop_name :
            raise ValueError("الحقول المطلوبة مفقودة: البريد الإلكتروني، النص، رقم المتجر، اسم المتجر")
        owner = self.user_model.find_by_id(dto.shop_id)
        if not owner:
            raise LookupError("المتجر غير موجود")
        db_shop_name = owner.get('shop_name')
        if not db_shop_name or db_shop_name.strip().lower() != dto.shop_name.strip().lower():
          raise LookupError("اسم المتجر غير صحيح")

        # 1. Check Duplicates
        existing_review = self.review_model.find_existing_review(dto.email, dto.shop_id)
        if existing_review:
            raise LookupError("لقد قمت بإرسال تقييم لهذا المتجر مسبقاً")

        # 2. Get Shop Type
        shop_type = owner.get('shop_type', 'عام') if owner else 'عام'

        # 3. Comprehensive AI Analysis (One Shot)
        analysis_result = self.deepseek_service.analyze_review_holistically(
            stars=dto.stars,
            shop_type=shop_type,
            enjoy_most=dto.enjoy_most,
            improve_product=dto.improve_product,
            additional_feedback=dto.additional_feedback
        )

        # 4. Optional: Local Validations (Safety Net)
        if analysis_result.is_spam or analysis_result.quality_score < 0.4:
            logging.warning(f"Low quality/Spam review detected from {dto.email}. Score: {analysis_result.quality_score}")

        if not analysis_result.context_match:
             logging.warning(f"Context mismatch detected for shop {dto.shop_id}")

        # 5. Construct Document
        # Format organized feedback to be richer than just tags
        themes_text = " - ".join(analysis_result.key_themes) if analysis_result.key_themes else "عام"
        organized_feedback_text = f"📝 الملخص: {analysis_result.summary}\n🏷️ المواضيع الرئيسية: {themes_text}"

        review_data = {
            "email": dto.email,
            "phone": dto.phone,
            "shop_id": dto.shop_id,
            "stars": dto.stars,
            
            # High-level data
            "overall_sentiment": analysis_result.sentiment,
            "category": analysis_result.category,
            "summary": analysis_result.summary,
            
            # Detailed content
            "organized_feedback": organized_feedback_text,
            "solutions": "\n".join(analysis_result.actionable_insights),
            "suggested_reply": analysis_result.suggested_reply,
            
            # Metadata
            "quality_score": analysis_result.quality_score,
            "is_spam": analysis_result.is_spam,
            "context_match": analysis_result.context_match,

            "original_fields": {
                "phone": dto.phone,
                "enjoy_most": dto.enjoy_most,
                "improve_product": dto.improve_product,
                "additional_feedback": dto.additional_feedback
            }
        }

        # 6. Persist
        review_id = self.review_model.create_review(review_data)
        logging.info(f"Review saved: {review_id}")

        # 7. Notify Owner
        if owner and (owner.get('device_token') or owner.get('telegram_chat_id')):
            self._send_notification(owner, dto, analysis_result)

        return {"review_id": review_id}

    def _send_notification(self, owner, dto, analysis: AnalysisResultDTO):
        message = f"تقييم جديد: {'⭐' * dto.stars}\n\"{dto.text}\"\nالنوع: {analysis.category}"
        
        # Add insights if negative or complaint
        if analysis.sentiment == 'سلبي' or analysis.category in ['شكوى', 'نقد']:
             if analysis.actionable_insights:
                 solutions_text = "\n- ".join(analysis.actionable_insights[:2]) # Top 2 insights
                 message += f"\n\n💡 نصيحة سريعة:\n- {solutions_text}"

        try:
            if owner.get('device_token'):
                self.notification_service.send_fcm_notification(owner['device_token'], message)
            elif owner.get('telegram_chat_id'):
                self.notification_service.send_telegram_notification(owner['telegram_chat_id'], message)
            else:
                logging.warning(f"No notification channel found for shop owner {dto.shop_id}")
        except Exception as e:
            logging.error(f"Notification failed: {e}")
