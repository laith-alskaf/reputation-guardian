import requests
import re
import unicodedata
import logging
from app.config import HF_TOKEN, HF_SENTIMENT_MODEL_URL, HF_TOXICITY_MODEL_URL
from app.dto.sentiment_analysis_result_dto import SentimentAnalysisResultDTO
from app.dto.review_dto import ReviewDTO
from app.services.external.text_profanity_service import TextProfanityService

class SentimentService:

    @staticmethod
    def clean_text(text: str) -> str:
        try:
            if not text or not isinstance(text, str):
                return ""
            text = unicodedata.normalize('NFKC', text)
            text = re.sub(r'[^a-zA-Z0-9\u0660-\u0669\u0600-\u06FF\s.,!?؛؟]', '', text).strip()
            return text
        except Exception as e:
            logging.error(f"Error cleaning text: {e}")
            return str(text) if text else ""

    @staticmethod
    def analyze_sentiment(text: str) -> str:
        if not text or not text.strip():
            return "محايد"

        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        url = HF_SENTIMENT_MODEL_URL
        try:
            response = requests.post(url, headers=headers, json={"inputs": text})
            if response.status_code == 200:
                result = response.json()
                label = None

                if isinstance(result, list) and result:
                    label = result[0].get("label", "neutral")
                elif isinstance(result, dict) and "labels" in result:
                    label = result["labels"][0]

                if label:
                    mapping = {
                        "positive": "إيجابي",
                        "إيجابي": "إيجابي",
                        "label_1": "إيجابي",
                        "negative": "سلبي",
                        "سلبي": "سلبي",
                        "label_0": "سلبي",
                        "neutral": "محايد"
                    }
                    return mapping.get(label.lower(), "محايد")

            else:
                logging.error(f"HuggingFace Sentiment API error: {response.status_code} - {response.text}")
        except Exception as e:
            logging.error(f"Sentiment analysis error: {e}")
        return "محايد"

    @staticmethod
    def analyze_toxicity(text: str) -> str:
        if not text or not text.strip():
            return "non-toxic"

        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        url = HF_TOXICITY_MODEL_URL

        toxic_label = "شتائم وكلام بذيء ومهين"
        safe_label = "نقد محترم وكلام عادي"

        try:
            response = requests.post(
                url,
                headers=headers,
                json={
                    "inputs": text,
                    "parameters": {
                        "candidate_labels": [toxic_label, safe_label],
                        "multi_label": False
                    }
                },
                timeout=10
            )

            if response.status_code == 200:
                result = response.json()
                labels = result.get("labels", [])
                scores = result.get("scores", [])

                if labels and scores:
                    top_label = labels[0]
                    top_score = scores[0]

                    if top_label == toxic_label and top_score > 0.60:
                        return "toxic"
                    elif top_label == toxic_label and top_score <= 0.60:
                        return "uncertain"
                    else:
                        return "non-toxic"

            elif response.status_code == 503:
                logging.info("Model loading, skipping toxicity check")
            else:
                logging.error(f"Toxicity API error: {response.status_code} - {response.text}")

        except Exception as e:
            logging.error(f"Toxicity analysis error: {e}")

        return "non-toxic"

    @staticmethod
    def classify_review(sentiment: str, toxicity: str, stars: int = None, text: str = "") -> str:
        sentiment_normalized = sentiment.lower() if sentiment else "neutral"
        is_negative_sentiment = sentiment_normalized in ["سلبي", "negative", "label_0"]
        is_positive_sentiment = sentiment_normalized in ["إيجابي", "positive", "label_1"]
        is_toxic = toxicity == "toxic"

        if stars is not None:
            if stars <= 2:
                is_negative_sentiment = True
                is_positive_sentiment = False
            elif stars >= 4:
                is_negative_sentiment = False
                is_positive_sentiment = True

        complaint_keywords = [
            "سرق", "انتزع", "خدع", "غش", "زبالة", "خري", "بخرا", "ما بنصح",
            "جربان", "كذب", "غير صادق", "سيء", "رديء", "مش حلو", "مش طيب"
        ]
        has_complaint_words = any(keyword in text.lower() for keyword in complaint_keywords)

        if is_negative_sentiment or has_complaint_words:
            if is_toxic or has_complaint_words:
                return "شكوى"
            else:
                return "نقد"
        elif is_positive_sentiment:
            return "إيجابي"
        else:
            if stars is not None:
                if stars <= 2:
                    return "نقد"
                elif stars >= 4:
                    return "إيجابي"
            return "إيجابي"

    @staticmethod
    def detect_review_quality(text: str, enjoy_most: str, improve_product: str, additional_feedback: str) -> dict:
        flags = []
        quality_score = 1.0
        all_text = f"{text} {enjoy_most} {improve_product} {additional_feedback}".strip()

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
            'is_suspicious': quality_score < 0.5 or len(flags) > 2
        }

    @staticmethod
    def detect_context_mismatch(text: str, shop_type: str) -> dict:
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
                labels = result.get("labels", [])
                scores = result.get("scores", [])

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
            'has_mismatch': False,
            'predicted_label': "Error"
        }

    @staticmethod
    def analyze_review_comprehensive(dto: ReviewDTO, shop_type: str) -> SentimentAnalysisResultDTO:
        cleaned_enjoy_most = SentimentService.clean_text(dto.enjoy_most or "")
        cleaned_improve_product = SentimentService.clean_text(dto.improve_product or "")
        cleaned_feedback = SentimentService.clean_text(dto.additional_feedback or "")
        cleaned_text = SentimentService.clean_text(dto.text or "")
        
        full_text_parts = [
            f"عدد النجوم: {dto.stars}" if dto.stars else "",
            f"أكثر ما أعجبني: {cleaned_enjoy_most}" if cleaned_enjoy_most else "",
            f"اقتراح للتحسين: {cleaned_improve_product}" if cleaned_improve_product else "",
            f"ملاحظات إضافية: {cleaned_feedback}" if cleaned_feedback else ""
        ]
        full_text = " | ".join([part for part in full_text_parts if part]).strip()

        if not full_text:
            full_text = cleaned_text

        sentiment = SentimentService.analyze_sentiment(full_text)
        toxicity = SentimentService.analyze_toxicity(full_text)
        category = SentimentService.classify_review(
            sentiment=sentiment,
            toxicity=toxicity,
            stars=dto.stars,
            text=full_text
        )

        quality_result = SentimentService.detect_review_quality(
            text=dto.text or "",
            enjoy_most=dto.enjoy_most or "",
            improve_product=dto.improve_product or "",
            additional_feedback=dto.additional_feedback or ""
        )

        context_result = SentimentService.detect_context_mismatch(full_text, shop_type)

        is_spam = quality_result.get('is_suspicious', False)
        context_match = not context_result.get('has_mismatch', False)

        return SentimentAnalysisResultDTO(
            sentiment=sentiment,
            toxicity=toxicity,
            category=category,
            quality_score=quality_result.get('quality_score', 1.0),
            is_spam=is_spam,
            context_match=context_match,
            quality_flags=quality_result.get('flags', []),
            mismatch_reasons=context_result.get('reasons', [])
        )

    @staticmethod
    def detect_and_censor_profanity_in_review(
        text: str = "",
        enjoy_most: str = "",
        improve_product: str = "",
        additional_feedback: str = "",
        use_hf: bool = True
    ) -> dict:
        result = {
            'text': {
                'original': text,
                'censored': text,
                'has_profanity': False,
                'profanity_score': 0.0,
                'censored_words': []
            },
            'enjoy_most': {
                'original': enjoy_most,
                'censored': enjoy_most,
                'has_profanity': False,
                'censored_words': []
            },
            'improve_product': {
                'original': improve_product,
                'censored': improve_product,
                'has_profanity': False,
                'censored_words': []
            },
            'additional_feedback': {
                'original': additional_feedback,
                'censored': additional_feedback,
                'has_profanity': False,
                'censored_words': []
            },
            'summary': {
                'total_fields_with_profanity': 0,
                'total_censored_words': [],
                'has_any_profanity': False,
                'overall_profanity_score': 0.0,
                'method': 'hf' if use_hf else 'regex'
            }
        }

        fields = [
            ('text', text),
            ('enjoy_most', enjoy_most),
            ('improve_product', improve_product),
            ('additional_feedback', additional_feedback)
        ]

        total_censored = []
        fields_with_profanity = 0
        total_score = 0.0

        for field_name, field_text in fields:
            if field_text and field_text.strip():
                if use_hf and field_name == 'text':
                    profanity_details = TextProfanityService.detect_profanity_with_hf(field_text)
                    has_profanity = profanity_details['has_profanity']
                    profanity_score = profanity_details['profanity_score']
                else:
                    profanity_details = TextProfanityService._detect_profanity_with_patterns(field_text)
                    has_profanity = profanity_details['has_profanity']
                    profanity_score = profanity_details['profanity_score']

                censored_text, censored_words = TextProfanityService.censor_profanity(
                    field_text,
                    censor_char='*',
                    method='word'
                )

                result[field_name]['censored'] = censored_text
                result[field_name]['has_profanity'] = has_profanity
                result[field_name]['profanity_score'] = profanity_score
                result[field_name]['censored_words'] = censored_words

                if has_profanity:
                    fields_with_profanity += 1
                    total_score += profanity_score

                total_censored.extend(censored_words)

        result['summary']['total_fields_with_profanity'] = fields_with_profanity
        result['summary']['total_censored_words'] = list(set(total_censored))
        result['summary']['has_any_profanity'] = fields_with_profanity > 0
        if fields_with_profanity > 0:
            result['summary']['overall_profanity_score'] = round(total_score / fields_with_profanity, 3)

        return result
