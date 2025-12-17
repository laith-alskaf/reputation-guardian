import requests
import re
import unicodedata
import logging
from app.presentation.config import HF_TOKEN, HF_SENTIMENT_MODEL_URL, HF_TOXICITY_MODEL_URL
from app.application.dto.sentiment_analysis_result_dto import SentimentAnalysisResultDTO
from app.application.dto.review_dto import ReviewDTO
from app.infrastructure.external.text_profanity_service import TextProfanityService
import time
class SentimentService:
    MAX_RETRIES = 3
    INITIAL_WAIT = 2.0  # ثواني    @staticmethod
    def clean_text(text: str) -> str:
        try:
            if not text or not isinstance(text, str):
                return ""
            text = unicodedata.normalize('NFKC', text)
            text = re.sub(r'[\u064B-\u065F\u0670]', '', text)
            text = re.sub(r'[\u0640]', '', text)
            text = re.sub(r'[أإآ]', 'ا', text)
            text = re.sub(r'(.)\1{2,}', r'\1\1', text)
            valid_chars_pattern = r'[^a-zA-Z0-9\u0600-\u06FF\s.,!?؛؟\:\_\-\(\)\U00010000-\U0010ffff\u2600-\u27BF]'
            text = re.sub(valid_chars_pattern, '', text).strip()
            text = re.sub(r'\s+', ' ', text).strip()

            return text

        except Exception as e:
            logging.error(f"Error cleaning text: {e}")
            return str(text) if text else ""

        except Exception as e:
            logging.error(f"Error cleaning text: {e}")
            return str(text) if text else ""
    # @staticmethod
    # def analyze_sentiment(text: str) -> str:
    #     if not text or not text.strip():
    #         return "محايد"

    #     headers = {"Authorization": f"Bearer {HF_TOKEN}"}
    #     url = HF_SENTIMENT_MODEL_URL
    #     try:
    #         response = requests.post(url, headers=headers, json={"inputs": text})
    #         if response.status_code == 200:
    #             result = response.json()
    #             label = None

    #             if isinstance(result, list) and result:
    #                 first_element = result[0]
    #                 if isinstance(first_element, list) and first_element:
    #                     if isinstance(first_element[0], dict):
    #                         label = first_element[0].get("label", "neutral")
    #                 elif isinstance(first_element, dict): 
    #                     label = first_element.get("label", "neutral")        
    #                 else:          
    #                         # تسجيل خطأ/تحذير إذا كانت القائمة تحتوي على عنصر غير متوقع
    #                     logging.warning(f"Sentiment API returned list but first element is not a dict: {first_element}")
    #             if label:
    #                 mapping = {
    #                     "positive": "إيجابي",
    #                     "إيجابي": "إيجابي",
    #                     "label_1": "إيجابي",
    #                     "negative": "سلبي",
    #                     "سلبي": "سلبي",
    #                     "label_0": "سلبي",
    #                     "neutral": "محايد"
    #                 }
    #                 return mapping.get(label.lower(), "محايد")

    #         else:
    #             logging.error(f"HuggingFace Sentiment API error: {response.status_code} - {response.text}")
    #     except Exception as e:
    #         logging.error(f"Sentiment analysis error: {e}")
    #     return "محايد"
    @staticmethod
    def analyze_sentiment(text: str) -> str:
        if not text or not text.strip():
            return "محايد"

        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        url = HF_SENTIMENT_MODEL_URL
        payload = {"inputs": text}

        for attempt in range(SentimentService.MAX_RETRIES):
            try:
                response = requests.post(url, headers=headers, json=payload, timeout=10)
                if response.status_code == 200:
                    return SentimentService._parse_response_to_string(response.json())
                elif response.status_code == 503:
                    error_data = response.json()
                    estimated_time = error_data.get("estimated_time", SentimentService.INITIAL_WAIT)
                    logging.info(f"Model loading... Waiting {estimated_time:.2f}s (Attempt {attempt+1})")
                    time.sleep(estimated_time)
                    continue 
                else:
                    logging.error(f"HF API Error {response.status_code}: {response.text}")
                    break

            except requests.exceptions.Timeout:
                logging.warning(f"HF API Timeout (Attempt {attempt+1})")
            except Exception as e:
                logging.error(f"Connection Error: {e}")
                break
        return "محايد"
    @staticmethod
    def _parse_response_to_string(result) -> str:
        try:
            predictions = []
            if isinstance(result, list) and result:
                if isinstance(result[0], list):
                    predictions = result[0]
                elif isinstance(result[0], dict):
                    predictions = result
            
            if not predictions:
                return "محايد"

            # ترتيب النتائج لأخذ الأعلى ثقة
            top_prediction = sorted(predictions, key=lambda x: x.get('score', 0), reverse=True)[0]
            raw_label = top_prediction.get('label', 'neutral').lower()

            mapping = {
                "positive": "إيجابي",
                "pos": "إيجابي",
                "label_2": "إيجابي",
                "label_1": "إيجابي",
                
                "negative": "سلبي",
                "neg": "سلبي",
                "label_0": "سلبي",
                
                "neutral": "محايد",
                "neu": "محايد",
                "label_1": "محايد" 
            }
            return mapping.get(raw_label, "محايد")

        except Exception as e:
            logging.error(f"Parsing Error: {e}")
            return "محايد"

    @staticmethod
    def analyze_toxicity(text: str) -> str:
        if not text or not text.strip():
            return "non-toxic"

        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        url = HF_TOXICITY_MODEL_URL

        toxic_label = "شتائم وكلام بذيء ومهين"
        safe_label = "نقد محترم وكلام عادي"

        payload = {
            "inputs": text,
            "parameters": {
                "candidate_labels": [toxic_label, safe_label],
                "multi_label": False  
            }
        }

        for attempt in range(SentimentService.MAX_RETRIES):
            try:
                response = requests.post(url, headers=headers, json=payload, timeout=70)
                if response.status_code == 200:
                    return SentimentService._parse_toxicity_response(
                        response.json(), 
                        toxic_label
                    )

                elif response.status_code == 503:
                    error_data = response.json()
                    estimated_time = error_data.get("estimated_time", SentimentService.INITIAL_WAIT)
                    logging.info(f"🛡️ Toxicity Model loading... Waiting {estimated_time:.2f}s")
                    time.sleep(estimated_time)
                    continue
                else:
                    logging.error(f"❌ Toxicity API Error {response.status_code}: {response.text}")
                    break

            except Exception as e:
                logging.error(f"❌ Toxicity Check Error: {e}")
                break
        return "uncertain"
    @staticmethod
    def _parse_toxicity_response(result, target_toxic_label) -> str:
        try:
            if isinstance(result, list):
                result = result[0] if result else {}

            if not isinstance(result, dict):
                return "uncertain"

            labels = result.get("labels", [])
            scores = result.get("scores", [])

            if not labels or not scores:
                return "uncertain"

            top_label = labels[0]
            top_score = scores[0]

            if top_label != target_toxic_label:
                if top_score < 0.60: 
                    return "uncertain"
                return "non-toxic"
            if top_label == target_toxic_label:
                if top_score >= 0.70:
                    return "toxic"
                elif top_score >= 0.50:
                    return "uncertain"
                else:
                    return "non-toxic"

            return "non-toxic"

        except Exception as e:
            logging.error(f"Parsing Toxicity Error: {e}")
            return "uncertain"

    @staticmethod
    def detect_review_quality( enjoy_most: str, improve_product: str, additional_feedback: str, pre_calculated_toxicity: str = None) -> dict:
        flags = []
        quality_score = 1.0
        all_text = f"{enjoy_most} {improve_product} {additional_feedback}".strip()

        if not all_text or len(all_text.strip()) < 3:
            return {
                'quality_score': 0.0,
                'flags': ['empty_content'],
                'is_suspicious': True
            }

        try:
            arabic_chars = sum(1 for c in all_text if '\u0600' <= c <= '\u06FF')
            english_chars = sum(1 for c in all_text if c.isascii() and c.isalpha())
            total_alpha = arabic_chars + english_chars
            if total_alpha < len(all_text) * 0.3:
                flags.append('gibberish_content')
                quality_score -= 0.3
        except Exception as e:
            logging.error(f"Language detection error: {e}")

        if total_alpha > 500:
            flags.append('too_long')
            quality_score -= 0.1

        if re.search(r'(.)\1{4,}', all_text):
            flags.append('repetitive_characters')
            quality_score -= 0.2

        special_chars = sum(1 for c in all_text if not c.isalnum() and not c.isspace() and c not in '.,!?؛،')
        if special_chars > len(all_text) * 0.2:
            flags.append('excessive_special_chars')
            quality_score -= 0.2

        # Use pre-calculated toxicity if available to save API calls
        if pre_calculated_toxicity:
            toxicity_score = pre_calculated_toxicity
        else:
            toxicity_score = SentimentService.analyze_toxicity(all_text)
            
        if toxicity_score == "toxic":
            flags.append('high_toxicity')
            quality_score -= 0.4

        words = all_text.split()
        if len(words) < 2:
            flags.append('too_short')
            quality_score -= 0.1

        if len(set(words)) < len(words) * 0.5:
            flags.append('repetitive_words')
            quality_score -= 0.2

        quality_score = max(0, quality_score)
        return {
            'quality_score': round(quality_score, 2),
            'flags': flags,
            'is_suspicious': quality_score < 0.5 or len(flags) > 2,
            'toxicity_status': toxicity_score
        }

    @staticmethod
    def detect_context_mismatch(text: str, shop_type: str) -> dict:
        """يكتشف ما إذا كان النص غير مرتبط بالسياق التجاري المحدد."""
        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        url = HF_TOXICITY_MODEL_URL

        shop_types_arabic = {
            "مطعم": "مطعم وأكل ومشروبات",
            "مقهى": "مقهى وقهوة ومشروبات",
            "محل ملابس": "ملابس وأزياء وموضة",
            "صيدلية": "صيدلية وأدوية وعلاج",
            "سوبر ماركت": "سوبر ماركت وتسوق ومنتجات",
            "متجر إلكترونيات": "إلكترونيات وأجهزة وتقنية",
            "مكتبة": "كتب وقراءة وتعليم",
            "محل تجميل": "تجميل وشعر وبشرة",
            "صالة رياضية": "رياضة وتمارين ولياقة",
            "مدرسة": "دراسة وتعليم وطلاب",
            "مستشفى": "طب وعلاج ومرضى",
            "محطة وقود": "وقود وسيارات وبنزين",
            "متجر أجهزة": "أجهزة وإلكترونيات وتقنية",
            "محل ألعاب": "ألعاب وترفيه وأطفال",
            "مكتب سياحي": "سفر وسياحة وفنادق",
            "محل هدايا": "هدايا وتذكارات ومناسبات",
            "مغسلة ملابس": "غسيل وتنظيف وملابس",
            "متجر هواتف": "هواتف وموبايلات وتقنية",
            "عام": "نشاط تجاري عام"
        }

        target_label = shop_types_arabic.get(shop_type, shop_type)
        general_label = "خدمة عملاء وتعامل عام ونظافة"
        other_label = "سياق آخر غير مرتبط"

        candidate_labels = [target_label, general_label, other_label]

        payload = {
            "inputs": text,
            "parameters": {
                "candidate_labels": candidate_labels,
                "multi_label": False
            }
        }

        try:
            response = requests.post(url, headers=headers, json=payload)

            if response.status_code == 503:
                logging.info("Model is loading, waiting...")
                import time
                time.sleep(20)
                response = requests.post(url, headers=headers, json=payload)

            if response.status_code == 200:
                result = response.json()
                labels = []
                scores = []
                
                if isinstance(result, list):
                    for item in result:
                        if isinstance(item, dict) and 'label' in item and 'score' in item:
                            labels.append(item['label'])
                            scores.append(item['score'])
                
                elif isinstance(result, dict):
                    labels = result.get("labels", [])
                    scores = result.get("scores", [])
                
                else:
                    logging.error(f"Context API returned unexpected type: {type(result)}. Full result: {result}")

                if labels and scores:
                    result_map = {label: score for label, score in zip(labels, scores)}

                    target_score = result_map.get(target_label, 0)
                    general_score = result_map.get(general_label, 0)
                    other_score = result_map.get(other_label, 0)

                    valid_relevance = target_score + general_score
                    has_mismatch = valid_relevance < 0.40

                    return {
                        'mismatch_score': round(other_score, 2),
                        'confidence': round(valid_relevance * 100, 2),
                        'reasons': [f"النص يبدو بعيداً عن سياق {shop_type} أو الخدمة العامة"] if has_mismatch else [],
                        'has_mismatch': has_mismatch,
                        'predicted_label': labels[0] if labels else None
                    }
            else:
                logging.error(f"HF API Error: {response.status_code} - {response.text}")

        except Exception as e:
            logging.error(f"Context mismatch detection error: {e}")

        return {
            'mismatch_score': 0.0,
            'confidence': 100.0,
            'reasons': 'لاشيء',
            'has_mismatch': False,
            'predicted_label': "Error"
        }    
    # def analyze_review_comprehensive(self,dto: ReviewDTO, shop_type: str) -> SentimentAnalysisResultDTO:
    #     cleaned_enjoy_most = SentimentService.clean_text(dto.enjoy_most or "")
    #     cleaned_improve_product = SentimentService.clean_text(dto.improve_product or "")
    #     cleaned_feedback = SentimentService.clean_text(dto.additional_feedback or "")
        
    #     full_text_parts = [
    #         f"عدد النجوم: {dto.stars}" if dto.stars else "",
    #         f"أكثر ما أعجبني: {cleaned_enjoy_most}" if cleaned_enjoy_most else "",
    #         f"اقتراح للتحسين: {cleaned_improve_product}" if cleaned_improve_product else "",
    #         f"ملاحظات إضافية: {cleaned_feedback}" if cleaned_feedback else ""
    #     ]
    #     full_text = " | ".join([part for part in full_text_parts if part]).strip()

    #     if not full_text:
    #         full_text = cleaned_text

    #     sentiment = SentimentService.analyze_sentiment(full_text)
    #     toxicity = SentimentService.analyze_toxicity(full_text)
    #     category = "عام" # Placeholder as classification is now handled by AI

    #     quality_result = SentimentService.detect_review_quality(
    #         enjoy_most=dto.enjoy_most or "",
    #         improve_product=dto.improve_product or "",
    #         additional_feedback=dto.additional_feedback or "",
    #         pre_calculated_toxicity=toxicity  # Pass the already calculated toxicity
    #     )

    #     context_result = SentimentService.detect_context_mismatch(full_text, shop_type)

    #     is_spam = quality_result.get('is_suspicious', False)
    #     context_match = not context_result.get('has_mismatch', False)

    #     return SentimentAnalysisResultDTO(
    #         sentiment=sentiment,
    #         toxicity=toxicity,
    #         category=category,
    #         quality_score=quality_result.get('quality_score', 1.0),
    #         is_spam=is_spam,
    #         context_match=context_match,
    #         quality_flags=quality_result.get('flags', []),
    #         mismatch_reasons=context_result.get('reasons', [])
    #     )

    # @staticmethod
    # def detect_and_censor_profanity_in_review(
    #     text: str = "",
    #     enjoy_most: str = "",
    #     improve_product: str = "",
    #     additional_feedback: str = "",
    #     use_hf: bool = True
    # ) -> dict:
    #     result = {
    #         'text': {
    #             'original': text,
    #             'censored': text,
    #             'has_profanity': False,
    #             'profanity_score': 0.0,
    #             'censored_words': []
    #         },
    #         'enjoy_most': {
    #             'original': enjoy_most,
    #             'censored': enjoy_most,
    #             'has_profanity': False,
    #             'censored_words': []
    #         },
    #         'improve_product': {
    #             'original': improve_product,
    #             'censored': improve_product,
    #             'has_profanity': False,
    #             'censored_words': []
    #         },
    #         'additional_feedback': {
    #             'original': additional_feedback,
    #             'censored': additional_feedback,
    #             'has_profanity': False,
    #             'censored_words': []
    #         },
    #         'summary': {
    #             'total_fields_with_profanity': 0,
    #             'total_censored_words': [],
    #             'has_any_profanity': False,
    #             'overall_profanity_score': 0.0,
    #             'method': 'hf' if use_hf else 'regex'
    #         }
    #     }

    #     fields = [
    #         ('text', text),
    #         ('enjoy_most', enjoy_most),
    #         ('improve_product', improve_product),
    #         ('additional_feedback', additional_feedback)
    #     ]

    #     total_censored = []
    #     fields_with_profanity = 0
    #     total_score = 0.0

    #     for field_name, field_text in fields:
    #         if field_text and field_text.strip():
    #             if use_hf and field_name == 'text':
    #                 profanity_details = TextProfanityService.detect_profanity_with_hf(field_text)
    #                 has_profanity = profanity_details['has_profanity']
    #                 profanity_score = profanity_details['profanity_score']
    #             else:
    #                 profanity_details = TextProfanityService._detect_profanity_with_patterns(field_text)
    #                 has_profanity = profanity_details['has_profanity']
    #                 profanity_score = profanity_details['profanity_score']

    #             censored_text, censored_words = TextProfanityService.censor_profanity(
    #                 field_text,
    #                 censor_char='*',
    #                 method='word'
    #             )

    #             result[field_name]['censored'] = censored_text
    #             result[field_name]['has_profanity'] = has_profanity
    #             result[field_name]['profanity_score'] = profanity_score
    #             result[field_name]['censored_words'] = censored_words

    #             if has_profanity:
    #                 fields_with_profanity += 1
    #                 total_score += profanity_score

    #             total_censored.extend(censored_words)

    #     result['summary']['total_fields_with_profanity'] = fields_with_profanity
    #     result['summary']['total_censored_words'] = list(set(total_censored))
    #     result['summary']['has_any_profanity'] = fields_with_profanity > 0
    #     if fields_with_profanity > 0:
    #         result['summary']['overall_profanity_score'] = round(total_score / fields_with_profanity, 3)

    #     return result
