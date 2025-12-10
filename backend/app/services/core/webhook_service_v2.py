import logging
from app.models.user import UserModel
from app.models.review import ReviewModel
from app.services.external.sentiment_service_v2 import SentimentServiceV2
from app.services.external.deepseek_service_v2 import DeepSeekServiceV2
from app.services.external.notification_service import NotificationService
from app.dto.review_dto import ReviewDTO

class WebhookService:
    def __init__(self):
        self.user_model = UserModel()
        self.review_model = ReviewModel()
        self.sentiment_service = SentimentServiceV2()
        self.deepseek_service = DeepSeekServiceV2()
        self.notification_service = NotificationService()

    def process_review(self, dto: ReviewDTO):
        if not dto.email or not dto.shop_id or not dto.shop_name:
            raise ValueError("الحقول المطلوبة مفقودة: البريد الإلكتروني، النص، رقم المتجر، اسم المتجر")

        owner = self.user_model.find_by_id(dto.shop_id)
        if not owner:
            raise LookupError("المتجر غير موجود")
        
        db_shop_name = owner.get('shop_name')
        if not db_shop_name or db_shop_name.strip().lower() != dto.shop_name.strip().lower():
            raise LookupError("اسم المتجر غير صحيح")

        existing_review = self.review_model.find_existing_review(dto.email, dto.shop_id)
        if existing_review:
            raise LookupError("لقد قمت بإرسال تقييم لهذا المتجر مسبقاً")

        shop_type = owner.get('shop_type', 'عام') if owner else 'عام'

        profanity_check = self.sentiment_service.detect_and_censor_profanity_in_review(
            enjoy_most=dto.enjoy_most or "",
            improve_product=dto.improve_product or "",
            additional_feedback=dto.additional_feedback or "",
            use_hf=True
        )

        if profanity_check['summary']['has_any_profanity']:
            logging.warning(
                f"Profanity detected in review from {dto.email}. "
                f"Fields affected: {profanity_check['summary']['total_fields_with_profanity']}, "
                f"Words: {profanity_check['summary']['total_censored_words']}"
            )

        sentiment_analysis = self.sentiment_service.analyze_review_comprehensive(dto, shop_type)

        logging.info(f"Sentiment Analysis Result for {dto.email}: {sentiment_analysis.to_dict()}")

        if sentiment_analysis.is_spam or sentiment_analysis.quality_score < 0.4:
            logging.warning(
                f"Low quality/Spam review detected from {dto.email}. "
                f"Score: {sentiment_analysis.quality_score}, Flags: {sentiment_analysis.quality_flags}"
            )

        if not sentiment_analysis.context_match:
            logging.warning(
                f"Context mismatch detected for shop {dto.shop_id}. "
                f"Reasons: {sentiment_analysis.mismatch_reasons}"
            )

        analysis_result = self.deepseek_service.format_insights_and_reply(
            dto=dto,
            sentiment_result=sentiment_analysis,
            shop_type=shop_type
        )

        logging.info(f"DeepSeek Analysis Result for {dto.email}: Summary={analysis_result.summary}")

        themes_text = " - ".join(analysis_result.key_themes) if analysis_result.key_themes else "عام"
        organized_feedback_text = f"📝 الملخص: {analysis_result.summary}\n🏷️ المواضيع الرئيسية: {themes_text}"

        review_data = {
            "email": dto.email,
            "phone": dto.phone,
            "shop_id": dto.shop_id,
            "stars": dto.stars,

            "overall_sentiment": sentiment_analysis.sentiment,
            "toxicity": sentiment_analysis.toxicity,
            "category": sentiment_analysis.category,
            "summary": analysis_result.summary,

            "organized_feedback": organized_feedback_text,
            "solutions": "\n".join(analysis_result.actionable_insights),
            "suggested_reply": analysis_result.suggested_reply,

            "quality_score": sentiment_analysis.quality_score,
            "quality_flags": sentiment_analysis.quality_flags,
            "is_spam": sentiment_analysis.is_spam,
            "context_match": sentiment_analysis.context_match,
            "mismatch_reasons": sentiment_analysis.mismatch_reasons,

            "profanity_check": {
                "has_any_profanity": profanity_check['summary']['has_any_profanity'],
                "fields_affected": profanity_check['summary']['total_fields_with_profanity'],
                "censored_words": profanity_check['summary']['total_censored_words'],
                "overall_score": profanity_check['summary']['overall_profanity_score'],
                "field_details": {
                    "text": {
                        "has_profanity": profanity_check['text']['has_profanity'],
                        "censored_words": profanity_check['text']['censored_words'],
                        "censored_text": profanity_check['text']['censored']
                    },
                    "enjoy_most": {
                        "has_profanity": profanity_check['enjoy_most']['has_profanity'],
                        "censored_words": profanity_check['enjoy_most']['censored_words'],
                        "censored_text": profanity_check['enjoy_most']['censored']
                    },
                    "improve_product": {
                        "has_profanity": profanity_check['improve_product']['has_profanity'],
                        "censored_words": profanity_check['improve_product']['censored_words'],
                        "censored_text": profanity_check['improve_product']['censored']
                    },
                    "additional_feedback": {
                        "has_profanity": profanity_check['additional_feedback']['has_profanity'],
                        "censored_words": profanity_check['additional_feedback']['censored_words'],
                        "censored_text": profanity_check['additional_feedback']['censored']
                    }
                }
            },

            "original_fields": {
                "phone": dto.phone,
                "enjoy_most": dto.enjoy_most,
                "improve_product": dto.improve_product,
                "additional_feedback": dto.additional_feedback
            }
        }

        review_id = self.review_model.create_review(review_data)
        logging.info(f"Review saved: {review_id}")

        if owner and (owner.get('device_token') or owner.get('telegram_chat_id')):
            self._send_notification(owner, dto, sentiment_analysis, analysis_result)

        return {"review_id": review_id}

    def _send_notification(self, owner, dto: ReviewDTO, sentiment_analysis, analysis_result):
        message = f"تقييم جديد: {'⭐' * dto.stars}\n\"\"\nالنوع: {sentiment_analysis.category}"

        if sentiment_analysis.sentiment == 'سلبي' or sentiment_analysis.category in ['شكوى', 'نقد']:
            if analysis_result.actionable_insights:
                solutions_text = "\n- ".join(analysis_result.actionable_insights[:2])
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
