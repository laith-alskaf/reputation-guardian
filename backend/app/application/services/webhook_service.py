import logging
from datetime import datetime
from typing import Tuple, Dict, Any
from bson import ObjectId

from app.presentation.config import QUALITY_GATE_THRESHOLD
from app.infrastructure.repositories import UserRepository, ReviewRepository
from app.infrastructure.external import SentimentService
from app.infrastructure.external import DeepSeekService
from app.infrastructure.external import NotificationService
from app.infrastructure.external import TelegramService
from app.infrastructure.external import QualityService
from app.application.dto.review_processing_dto import ReviewDocument, Source, Processing
from app.application.dto.sentiment_analysis_result_dto import SentimentAnalysisResultDTO
from app.application.dto.analysis_result_dto import AnalysisResultDTO

class WebhookService:
    def __init__(self, user_repository: UserRepository = None, review_repository: ReviewRepository = None, telegram_service: TelegramService = None):
        """Initialize WebhookService with dependency injection."""
        self.user_repository = user_repository or UserRepository()
        self.review_repository = review_repository or ReviewRepository()
        self.sentiment_service = SentimentService()
        self.deepseek_service = DeepSeekService()
        self.notification_service = NotificationService()
        self.telegram_service = telegram_service or TelegramService(self.notification_service)
        self.quality_service = QualityService()

    def _extract_form_fields(self, fields: list) -> Dict[str, Any]:
        """Extracts key information from the Tally 'fields' array."""
        extracted_data = {
            "rating": 0,
            "source_fields": {},
            "shop_id": None,
            "respondent_email": None,
            "respondent_phone": None,
            "shop_type": "عام",
            "shop_name": None
        }

        for field in fields:
            label = field.get('label')
            value = field.get('value')
            
            if label:
                extracted_data["source_fields"][label] = value

            if label == 'shop_id':
                extracted_data["shop_id"] = value
            elif label == 'email':
                extracted_data["respondent_email"] = value
            elif label == 'phone':  # إضافة معالجة رقم الهاتف
                extracted_data["respondent_phone"] = value
            elif label == 'shop_type':
                extracted_data["shop_type"] = value or "عام"
            elif label == 'shop_name':
                extracted_data["shop_name"] = value
            elif field.get('type') == 'RATING' or label == 'stars':
                try:
                    extracted_data["rating"] = int(value)
                except (ValueError, TypeError):
                    logging.warning(f"Could not parse rating value: {value}")
                    extracted_data["rating"] = 0
        
        return extracted_data

    def _prepare_initial_data(self, extracted_fields: Dict[str, Any]) -> Tuple[Source, Processing]:
        source_obj = Source(
            rating=extracted_fields.get('rating', 0), 
            fields=extracted_fields.get('source_fields', {})
        )

        # استخراج الحقول النصية الثلاثة المحددة
        source_fields = extracted_fields.get('source_fields', {})
        text_parts = []
        
        for field_name in ['enjoy_most', 'improve_product', 'additional_feedback']:
            field_value = source_fields.get(field_name, '')
            if field_value and isinstance(field_value, str) and field_value.strip():
                text_parts.append(field_value.strip())
        
        concatenated_text = " ".join(text_parts)
        
        # تنظيف النص فقط - السمية ستُحسب لاحقاً في التدفق
        cleaned_text = SentimentService.clean_text(concatenated_text)

        processing_obj = Processing(
            concatenated_text=cleaned_text,
            is_profane=False  # سيتم تحديدها لاحقاً من خلال تحليل السمية
        )

        return source_obj, processing_obj

    def _is_high_quality(self, quality_result: dict) -> bool:
        """Determines if a review meets the quality threshold."""
        score = quality_result.get('quality_score', 0.0)
        is_suspicious = quality_result.get('is_suspicious', True)

        if is_suspicious:
            logging.warning(f"Review is suspicious with flags: {quality_result.get('flags')}")
            return False
        
        if score < QUALITY_GATE_THRESHOLD:
            logging.warning(f"Review quality score ({score}) is below threshold ({QUALITY_GATE_THRESHOLD})")
            return False
            
        return True

    def process_review(self, form_data: Dict[str, Any]):
        """
        Processes a new review from a webhook, applying a sequential quality and
        relevancy gate before committing to expensive analysis.
        """
        # --- 1. Data Extraction & Validation ---
        fields = form_data.get('data', {}).get('fields', [])
        if not fields:
            raise ValueError("Payload is missing 'data.fields' array.")
            
        extracted_fields = self._extract_form_fields(fields)
        
        shop_id = extracted_fields.get('shop_id')
        if not shop_id:
            raise ValueError("`shop_id` is missing from the form fields.")

        owner = self.user_repository.find_by_id(ObjectId(shop_id))
        if not owner:
            raise LookupError(f"Shop with ID '{shop_id}' not found.")

        respondent_email = extracted_fields.get('respondent_email')
        if respondent_email:
            existing_review = self.review_repository.find_existing_review(respondent_email, shop_id)
            if existing_review:
                raise LookupError(f"A review from '{respondent_email}' for shop '{shop_id}' already exists.")

        # --- 2. Initial Data Preparation ---
        source, processing = self._prepare_initial_data(extracted_fields)
        # --- 3. Pre-calculate Toxicity (once for the entire flow) ---
        toxicity_status = self.sentiment_service.analyze_toxicity(processing.concatenated_text)
        
        # --- 4. Quality Gate (Gate 1) ---
        source_fields = extracted_fields.get('source_fields', {})
        enjoy_most = source_fields.get('enjoy_most', '')
        improve_product = source_fields.get('improve_product', '')
        additional_feedback = source_fields.get('additional_feedback', '')
        
        quality_result = self.quality_service.assess_quality(
            enjoy_most=enjoy_most,
            improve_product=improve_product,
            additional_feedback=additional_feedback,
            rating=source.rating,
            toxicity_status=toxicity_status
        )
        quality_check_result = quality_result.to_dict()

        if not self._is_high_quality(quality_check_result):
            rejected_doc = ReviewDocument(
                id=str(ObjectId()),
                shop_id=shop_id,
                email=respondent_email,
                stars=source.rating,
                status="rejected_low_quality",
                overall_sentiment="محايد",
                source=source,
                processing=processing,
                analysis={'quality': quality_check_result}
            )
            self.review_repository.create_review(rejected_doc.model_dump(by_alias=True))
            logging.warning(f"Rejected low-quality review for shop {shop_id}. Flags: {quality_check_result.get('flags')}")
            return {"status": "rejected_low_quality", "reason": "Review did not meet quality standards."}

        logging.info(f"Review for shop {shop_id} passed Quality Gate.")

        # --- 5. Relevancy Gate (Gate 2) ---
        shop_type = extracted_fields.get('shop_type', 'عام')
        raw_text = processing.concatenated_text
        context_check_result = self.sentiment_service.detect_context_mismatch(raw_text, shop_type)

        if context_check_result.get('has_mismatch'):
            rejected_doc = ReviewDocument(
                id=str(ObjectId()),
                shop_id=shop_id,
                email=respondent_email,
                stars=source.rating,
                status="rejected_irrelevant", # Use specific status
                overall_sentiment="محايد",
                source=source,
                processing=processing,
                analysis={
                    'quality': quality_check_result,
                    'context': context_check_result
                }
            )
            self.review_repository.create_review(rejected_doc.model_dump(by_alias=True))
            logging.warning(f"Rejected irrelevant review for shop {shop_id}. Reason: {context_check_result.get('reasons')}")
            return {"status": "rejected_irrelevant", "reason": "Review content is not relevant to the shop category."}
        
        logging.info(f"Review for shop {shop_id} passed Relevancy Gate.")

        # --- 6. Full Analysis (for High-Quality, Relevant Reviews) ---
        logging.info(f"Proceeding with full analysis for shop {shop_id}.")
        
        # A) Comprehensive Sentiment & Classification
        sentiment = self.sentiment_service.analyze_sentiment(processing.concatenated_text)
        
        # Reuse pre-calculated toxicity from step 3
        toxicity = toxicity_status
            
        
        # B) Deepseek AI Analysis for insights and replies
        temp_sentiment_dto = SentimentAnalysisResultDTO(
            sentiment=sentiment, toxicity=toxicity, category="pending", quality_score=quality_check_result.get('quality_score', 1.0),
            is_spam=False, context_match=True, quality_flags=[], mismatch_reasons=[]
        )
        
        class TempReviewDTO:
            def __init__(self, source_obj, processing_obj):
                self.stars = source_obj.rating
                self.full_text = processing_obj.concatenated_text
                self._source_fields = source_obj.fields
                
                self.enjoy_most = self._get_field_value("enjoy_most")
                self.improve_product = self._get_field_value("improve_product")
                self.additional_feedback = self._get_field_value("additional_feedback")

            def _get_field_value(self, label):
                return self._source_fields.get(label, "")

        temp_review_dto = TempReviewDTO(source, processing)
        
        deepseek_result: AnalysisResultDTO = self.deepseek_service.format_insights_and_reply(
            dto=temp_review_dto,
            sentiment_result=temp_sentiment_dto,
            shop_type=shop_type
        )
        
        # --- 6. Final Document Assembly & Saving ---
        processed_doc = ReviewDocument(
            id=str(ObjectId()),
            shop_id=shop_id,
            email=respondent_email,
            stars=source.rating,
            overall_sentiment=sentiment,
            status="processed",
            source=source,
            processing=processing,
            analysis={
                "sentiment": sentiment,
                "toxicity": toxicity,
                "category": deepseek_result.category,
                "quality": quality_check_result,
                "context": context_check_result, # Include context result
                "key_themes": deepseek_result.key_themes,
            },
            generated_content={
                "summary": deepseek_result.summary,
                "actionable_insights": deepseek_result.actionable_insights,
                "suggested_reply": deepseek_result.suggested_reply,
            }
        )

        review_id = self.review_repository.create_review(processed_doc.model_dump(by_alias=True))
        logging.info(f"Successfully processed and saved review {review_id} for shop {shop_id}.")

        # --- 7. Notification ---
        if owner and (owner.device_token or owner.telegram_chat_id):
            self._send_notification(owner, processed_doc)

        return {"status": "processed", "review_id": str(review_id)}

    def _send_notification(self, owner, review_doc: ReviewDocument):
        """Sends notification based on the processed review document."""
        try:
            if owner.device_token:
                # Simple FCM notification (no rich formatting)
                stars = '⭐' * (review_doc.source.rating or 0)
                sentiment = review_doc.analysis.get('sentiment', 'محايد')
                message = f"تقييم جديد: {stars}\n{sentiment}"
                self.notification_service.send_fcm_notification(owner.device_token, message)
            elif owner.telegram_chat_id:
                # Rich formatted Telegram notification
                self.telegram_service.send_review_notification(owner.telegram_chat_id, review_doc)
        except Exception as e:
            logging.error(f"Notification failed for shop {review_doc.shop_id}: {e}")

    def process_telegram_webhook(self, update_data: Dict[str, Any]):
        """
        Processes telegram webhook updates.
        Expected payload structure from Telegram:
        {
            "message": {
                "chat": {"id": 12345},
                "text": "/start <user_id_encoded>"
            }
        }
        """
        try:
            chat_id = update_data.get('message', {}).get('chat', {}).get('id')
            text = update_data.get('message', {}).get('text', '')
            
            if not chat_id:
                logging.warning("No chat_id in telegram webhook")
                return
            
            # Handle /start command with user ID
            if text.startswith('/start'):
                parts = text.split()
                if len(parts) > 1:
                    # Decode user_id from start parameter
                    user_id_payload = parts[1]
                    # Assuming user_id is the encoded object ID
                    self.user_repository.update_user(ObjectId(user_id_payload), {"telegram_chat_id": str(chat_id)})
                    
                    # Send connection success message
                    try:
                        self.telegram_service.send_connection_success(chat_id)
                    except Exception as e:
                        logging.error(f"Failed to send confirmation: {e}")
                else:
                    self.telegram_service.send_connection_error(chat_id)
            else:
                self.telegram_service.send_welcome_message(chat_id)
                
        except Exception as e:
            logging.error(f"Error processing telegram webhook: {e}")
