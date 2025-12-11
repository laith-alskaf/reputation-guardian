import logging
from datetime import datetime
from typing import Tuple, Dict, Any
from bson import ObjectId

from app import config
from app.models.user import UserModel
from app.models.review import ReviewModel
from app.services.external.sentiment_service import SentimentService
from app.services.external.deepseek_service import DeepSeekService
from app.services.external.notification_service import NotificationService
from app.services.external.text_profanity_service import TextProfanityService
from app.dto.review_processing_dto import ReviewDocument, Source, Processing
from app.dto.sentiment_analysis_result_dto import SentimentAnalysisResultDTO
from app.dto.analysis_result_dto import AnalysisResultDTO

class WebhookService:
    def __init__(self):
        self.user_model = UserModel()
        self.review_model = ReviewModel()
        self.sentiment_service = SentimentService()
        self.profanity_service = TextProfanityService()
        self.deepseek_service = DeepSeekService()
        self.notification_service = NotificationService()

    def _extract_form_fields(self, fields: list) -> Dict[str, Any]:
        """Extracts key information from the Tally 'fields' array."""
        extracted_data = {
            "rating": 0,
            "text_parts": [],
            "source_fields": {},
            "shop_id": None,
            "respondent_email": None,
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
            elif label == 'shop_type':
                extracted_data["shop_type"] = value or "عام"
            elif label == 'shop_name':
                extracted_data["shop_name"] = value
            elif field.get('type') == 'RATING':
                try:
                    extracted_data["rating"] = int(value)
                except (ValueError, TypeError):
                    logging.warning(f"Could not parse rating value: {value}")
                    extracted_data["rating"] = 0
            elif field.get('type') in ['INPUT_TEXT', 'TEXTAREA']:
                if isinstance(value, str) and value.strip():
                    extracted_data["text_parts"].append(value)
        
        return extracted_data

    def _prepare_initial_data(self, extracted_fields: Dict[str, Any]) -> Tuple[Source, Processing]:
        """Builds the source and processing objects from extracted form fields."""
        source_obj = Source(
            rating=extracted_fields.get('rating', 0), 
            fields=extracted_fields.get('source_fields', {})
        )

        concatenated_text = " ".join(extracted_fields.get('text_parts', []))
        
        profanity_analysis = self.profanity_service.analyze_and_censor(concatenated_text, use_hf=False)

        processing_obj = Processing(
            concatenated_text=profanity_analysis['censored_text'],
            is_profane=profanity_analysis['has_profanity']
        )

        return source_obj, processing_obj

    def _is_high_quality(self, quality_result: dict) -> bool:
        """Determines if a review meets the quality threshold."""
        score = quality_result.get('quality_score', 0.0)
        is_suspicious = quality_result.get('is_suspicious', True)

        if is_suspicious:
            logging.warning(f"Review is suspicious with flags: {quality_result.get('flags')}")
            return False
        
        if score < config.QUALITY_GATE_THRESHOLD:
            logging.warning(f"Review quality score ({score}) is below threshold ({config.QUALITY_GATE_THRESHOLD})")
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

        owner = self.user_model.find_by_id(shop_id)
        if not owner:
            raise LookupError(f"Shop with ID '{shop_id}' not found.")

        respondent_email = extracted_fields.get('respondent_email')
        if respondent_email:
            existing_review = self.review_model.find_existing_review(respondent_email, shop_id)
            if existing_review:
                raise LookupError(f"A review from '{respondent_email}' for shop '{shop_id}' already exists.")

        # --- 2. Initial Data Preparation ---
        source, processing = self._prepare_initial_data(extracted_fields)
        
        # --- 3. Quality Gate (Gate 1) ---
        raw_text = " ".join(extracted_fields.get('text_parts', []))
        quality_check_result = self.sentiment_service.detect_review_quality(raw_text, "", "")

        if not self._is_high_quality(quality_check_result):
            rejected_doc = ReviewDocument(
                id=str(ObjectId()),
                shop_id=shop_id,
                email=respondent_email,
                stars=source.rating,
                status="rejected_low_quality", # Use specific status
                overall_sentiment="محايد",
                source=source,
                processing=processing,
                analysis={'quality': quality_check_result}
            )
            self.review_model.create_review(rejected_doc.model_dump(by_alias=True))
            logging.warning(f"Rejected low-quality review for shop {shop_id}. Flags: {quality_check_result.get('flags')}")
            return {"status": "rejected_low_quality", "reason": "Review did not meet quality standards."}

        logging.info(f"Review for shop {shop_id} passed Quality Gate.")

        # --- 4. Relevancy Gate (Gate 2) ---
        shop_type = extracted_fields.get('shop_type', 'عام')
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
            self.review_model.create_review(rejected_doc.model_dump(by_alias=True))
            logging.warning(f"Rejected irrelevant review for shop {shop_id}. Reason: {context_check_result.get('reasons')}")
            return {"status": "rejected_irrelevant", "reason": "Review content is not relevant to the shop category."}
        
        logging.info(f"Review for shop {shop_id} passed Relevancy Gate.")

        # --- 5. Full Analysis (for High-Quality, Relevant Reviews) ---
        logging.info(f"Proceeding with full analysis for shop {shop_id}.")
        
        # A) Comprehensive Sentiment & Classification
        sentiment = self.sentiment_service.analyze_sentiment(processing.concatenated_text)
        toxicity = self.sentiment_service.analyze_toxicity(processing.concatenated_text)
        category = self.sentiment_service.classify_review(
            sentiment=sentiment,
            toxicity=toxicity,
            stars=source.rating,
            text=processing.concatenated_text
        )
        
        # B) Deepseek AI Analysis for insights and replies
        temp_sentiment_dto = SentimentAnalysisResultDTO(
            sentiment=sentiment, toxicity=toxicity, category=category, quality_score=quality_check_result.get('quality_score', 1.0),
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
                "category": category,
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

        review_id = self.review_model.create_review(processed_doc.model_dump(by_alias=True))
        logging.info(f"Successfully processed and saved review {review_id} for shop {shop_id}.")

        # --- 7. Notification ---
        if owner and (owner.get('device_token') or owner.get('telegram_chat_id')):
            self._send_notification(owner, processed_doc)

        return {"status": "processed", "review_id": str(review_id)}

    def _send_notification(self, owner: Dict[str, Any], review_doc: ReviewDocument):
        """Sends notification based on the new processed review document."""
        stars_display = '⭐' * review_doc.source.rating if review_doc.source.rating else "بدون تقييم"
        message = f"تقييم جديد: {stars_display}\n""\n""النوع: {review_doc.analysis.get('category', 'عام')}"

        is_negative = review_doc.analysis.get('sentiment') == 'سلبي' or review_doc.analysis.get('category') in ['شكوى', 'نقد']
        
        if is_negative:
            insights = review_doc.generated_content.get('actionable_insights', [])
            if insights:
                solutions_text = "\n- ".join(insights[:2])
                message += f"\n\n💡 نصيحة سريعة:\n- {solutions_text}"

        try:
            if owner.get('device_token'):
                self.notification_service.send_fcm_notification(owner['device_token'], message)
            elif owner.get('telegram_chat_id'):
                self.notification_service.send_telegram_notification(owner['telegram_chat_id'], message)
        except Exception as e:
            logging.error(f"Notification failed for shop {review_doc.shop_id}: {e}")
