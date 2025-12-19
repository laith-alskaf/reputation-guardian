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
    INITIAL_WAIT = 2.0  # ثواني  
    MIN_TOP_SCORE_SHORT_TEXT = 0.5
    staticmethod
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
            labels, scores = [], []

            if isinstance(result, dict):
                 labels = result.get("labels", [])
                 scores = result.get("scores", [])
            elif isinstance(result, list):
                 for item in result:
                    if isinstance(item, dict):
                        labels.append(item.get("label"))
                        scores.append(item.get("score"))
                        
            # if isinstance(result, list):
            #     result = result[0] if result else {}

            # if not isinstance(result, dict):
            #     logging.warning("❌ not isinstance(result, dict)  uncertain")
            #     return "uncertain"

            # labels = result.get("labels", [])
            # scores = result.get("scores", [])
            res_map = dict(zip(labels, scores))
            if not labels or not scores:
                logging.warning("❌ not labels or not scores")
                return "uncertain"

            top_label = labels[0]
            top_score = scores[0]

            if top_label == target_toxic_label and top_score >= 0.60:
                logging.warning("❌ top_label == target_toxic_label and top_score >= 0.60")
                return "toxic"
            if top_label == target_toxic_label and top_score >= 0.40:
                logging.warning("❌  top_label == target_toxic_label and top_score >= 0.40")
                return "uncertain"
            if res_map.get(target_toxic_label, 0) < 0.35:
                logging.warning("❌ res_map.get(target_toxic_label, 0) < 0.35")
                return "non-toxic"
       
            logging.warning("❌ uncertain uncertain")
            return "uncertain"

        except Exception as e:
            logging.error(f"Parsing Toxicity Error: {e}")
            return "uncertain"

    # NOTE: detect_review_quality has been moved to quality_service.py
    # Use QualityService.assess_quality() instead

    @staticmethod
    def detect_context_mismatch(text: str, shop_type: str) -> dict:
        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        url = HF_TOXICITY_MODEL_URL

        shop_types_arabic = {
            "مطعم": "أكل وطعام ووجبات ومنيو ومطاعم وطبخ وأطباق وجوع",
            "مقهى": "قهوة وكافيه وحلا ومشروبات وباريستا وجلسة روقان",
            "محل ملابس": "أزياء ولبس وقماش وموضة ومقاسات وتفصيل وبراندات",
            "صيدلية": "دواء وعلاج وصيدليات ووصفة طبية وفيتامينات وشاش",
            "سوبر ماركت": "بقالة ومقاضي وتسوق ومنتجات غذائية ومعلبات وخضار",
            "متجر إلكترونيات": "أجهزة ذكية وشاشات وكمبيوترات وتقنية وقطع غيار وصيانة",
            "مكتبة": "كتب وقراءة وقرطاسية وأدوات مدرسية وروايات وتعليم",
            "محل تجميل": "مكياج وبشرة وشعر وعطورات ومستحضرات تجميل وعناية",
            "صالة رياضية": "جيم وتمارين وحديد ولياقة ورياضة ومدرب وعضلات",
            "مدرسة": "تعليم وطلاب ومدرسين وكتب ودوام مدرسي وفصول ودراسة",
            "مستشفى": "طب ومرضى وعلاج ودكاترة وعيادات وفحوصات وعمليات",
            "محطة وقود": "بنزين وسيارات وزيت ووقود وتعبئة وإطارات ومغسلة سيارات",
            "متجر أجهزة": "أجهزة كهربائية ومنزلية وغسالات وثلاجات ومكيفات",
            "محل ألعاب": "ألعاب أطفال وترفيه وهدايا صغار وبلايستيشن وعرائس",
            "مكتب سياحي": "سفر وسياحة وطيران وفنادق وحجوزات ورحلات وتذاكر",
            "محل هدايا": "هدايا وتغليف وورد ومناسبات وتذكارات وتحف",
            "مغسلة ملابس": "غسيل وكوي وتنظيف جاف وبقع ملابس ومصبغة",
            "متجر هواتف": "جوالات وموبايلات وإكسسوارات هواتف وشواحن وصيانة موبايل",
            "عام": "تجربة العميل ومستوى الخدمة والمكان والتعامل والأسعار"
        }

        target_label = shop_types_arabic.get(shop_type, shop_type)


        candidate_labels = [
            target_label,
            "خدمة عملاء وتعامل عام ونظافة",
            f"سياق آخر غير مرتبط ب{target_label} وايضا غير مرتبط ب خدمة العملاء وتعامل عام ونظافة"
        ]
        text_clean = text.strip()
        payload = {
            "inputs": text_clean,
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
                            num_words = len(text_clean.split())
                            if num_words <= 5:
                                if top_score < SentimentService.MIN_TOP_SCORE_SHORT_TEXT:
                                    has_mismatch = False
                                else:
                                    has_mismatch = top_label != target_label

                            else:
                                
                                target_score = result_map.get(target_label, 0.0)+result_map.get(candidate_labels[1], 0.0)
                                if top_score < 0.6 :
                                    has_mismatch = True
                                    predicted_label = "غير مرتبط"
                                else:
                                    has_mismatch = (top_label != target_label and top_score >= 0.5) and (target_score < 0.5)
                                    predicted_label = top_label
                            confidence = round(result_map.get(target_label, 0.0) * 100, 2)
                            return {
                                'mismatch_score': round(top_score, 2),
                                'confidence': confidence,
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

