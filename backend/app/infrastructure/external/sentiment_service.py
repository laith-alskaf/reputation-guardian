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
    def detect_review_quality(enjoy_most: str, improve_product: str, additional_feedback: str, rating: int = 0, pre_calculated_toxicity: str = None) -> dict:
        flags = []
        quality_score = 1.0

        parts = [p.strip() for p in [enjoy_most, improve_product, additional_feedback] if p and p.strip()]
        all_text = " ".join(parts)

        # حالة خاصة: تقييم بالنجوم فقط (بدون نص)
        if not all_text or len(all_text) < 3:
            # إذا كان هناك تقييم بالنجوم، نقبل التقييم
            if rating > 0:
                flags_for_stars = ['stars_only']
                # إضافة flag بناءً على التقييم بالنجوم (اقتراح المستخدم)
                if rating <= 2:
                    flags_for_stars.append('negative_stars')
                elif rating >= 4:
                    flags_for_stars.append('positive_stars')
                else:
                    flags_for_stars.append('neutral_stars')
                
                return {
                    'quality_score': 1.0,
                    'flags': flags_for_stars,
                    'is_suspicious': False,
                    'toxicity_status': pre_calculated_toxicity or "non-toxic"
                }
            # إذا لم يكن هناك نجوم ولا نص، نرفض
            else:
                return {
                    'quality_score': 0.0,
                    'flags': ['empty_content'],
                    'is_suspicious': True,
                    'toxicity_status': pre_calculated_toxicity or "non-toxic"
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

        words = all_text.split()
        if len(words) > 200 or total_alpha > 500:
            flags.append('too_long')
            quality_score -= 0.1

        if re.search(r'(.)\1{4,}', all_text):
            flags.append('repetitive_characters')
            quality_score -= 0.2

        special_chars = sum(1 for c in all_text if not c.isalnum() and not c.isspace() and c not in '.,!?؛،')
        if special_chars > len(all_text) * 0.2:
            flags.append('excessive_special_chars')
            quality_score -= 0.2

        toxicity_score = pre_calculated_toxicity or SentimentService.analyze_toxicity(all_text)
        if toxicity_score == "toxic":
            flags.append('high_toxicity')
            quality_score -= 0.4
        elif toxicity_score == "uncertain":
            flags.append('possible_toxicity')
            quality_score -= 0.1

        if len(words) < 2:
            flags.append('too_short')
            quality_score -= 0.05  # تقليل العقوبة من 0.1 إلى 0.05

        unique_words = set(words)
        # تطبيق فحص التكرار فقط إذا كان عدد الكلمات > 3
        if len(words) > 3 and len(unique_words) < len(words) * 0.4:
            flags.append('repetitive_words')
            # عقوبة أكبر للتكرار الشديد
            repetition_ratio = len(unique_words) / len(words)
            if repetition_ratio < 0.25:  # تكرار شديد جداً (75%+ من نفس الكلمة)
                quality_score -= 0.4
            else:
                quality_score -= 0.3  # زيادة من 0.2 إلى 0.3

        quality_score = max(0, quality_score)

        # تحديد is_suspicious بشكل أكثر ذكاءً
        is_suspicious = False

        # حالات تلقائية للـ suspicious
        if quality_score < 0.4:  # تغيير من 0.5 إلى 0.4
            is_suspicious = True
        elif toxicity_score == "toxic":  # محتوى سام → suspicious تلقائياً
            is_suspicious = True
        elif 'repetitive_words' in flags and quality_score < 0.6:  # تكرار + درجة منخفضة
            is_suspicious = True
        elif len(flags) >= 3:  # 3 أعلام أو أكثر
            is_suspicious = True

        return {
            'quality_score': round(quality_score, 2),
            'flags': flags,
            'is_suspicious': is_suspicious,
            'toxicity_status': toxicity_score
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

        # فئات إضافية لتقليل الأخطاء
        candidate_labels = [
            target_label,
            "خدمة عملاء وتعامل عام ونظافة",
            "رياضة وأحداث رياضية",
            "سياسة وأخبار عامة",
            "ترفيه ومشاهير",
            "حياة شخصية أو يوميات",
            "سياق آخر غير مرتبط"
        ]

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
                labels, scores = [], []

                if isinstance(result, dict):
                    labels = result.get("labels", [])
                    scores = result.get("scores", [])
                elif isinstance(result, list):
                    for item in result:
                        if isinstance(item, dict):
                            labels.append(item.get("label"))
                            scores.append(item.get("score"))

                if labels and scores:
                            result_map = {label: score for label, score in zip(labels, scores)}
                            top_label, top_score = labels[0], scores[0]

                            target_score = result_map.get(target_label, 0.0)

                            # منطق mismatch الجديد
                            if top_score < 0.4:
                                has_mismatch = True
                                predicted_label = "غير مرتبط"
                            else:
                                has_mismatch = (top_label != target_label and top_score >= 0.5) or (target_score < 0.5)
                                predicted_label = top_label

                            return {
                                'mismatch_score': round(top_score, 2),
                                'confidence': round(target_score * 100, 2),
                                'reasons': [f"النص بعيد عن سياق {shop_type}"] if has_mismatch else [],
                                'has_mismatch': has_mismatch,
                                'predicted_label': predicted_label
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

