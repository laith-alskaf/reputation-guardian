import requests
import re
import unicodedata
import logging
from app.config import HF_TOKEN
from app.services_interfaces import ISentimentService

class SentimentService(ISentimentService):

    @staticmethod
    def clean_text(text: str) -> str:
        try:
            if not text or not isinstance(text, str):
              return ""
            text = unicodedata.normalize('NFKC', text)
            text = re.sub(r'[^\u0600-\u06FF\s]', '', text).strip()
            return text
        except Exception as e:
            logging.error(f"Error cleaning text: {e}")
            return str(text) if text else ""

    @staticmethod
    def analyze_sentiment(text: str) -> str:
        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        url = "https://router.huggingface.co/models/CAMeL-Lab/bert-base-arabic-camelbert-da-sentiment"
        try:
            response = requests.post(url, headers=headers, json={"inputs": text})
            if response.status_code == 200:
                result = response.json()
                if isinstance(result, list) and result:
                    label = result[0].get("label", "neutral")
                    # تحويل التصنيف إلى قيم عربية موحدة
                    if label.lower() in ["positive", "إيجابي", "label_1"]:
                        return "إيجابي"
                    elif label.lower() in ["negative", "سلبي", "label_0"]:
                        return "سلبي"
                    else:
                        return "محايد"
            else:
                logging.error(f"HuggingFace Sentiment API error: {response.status_code} - {response.text}")
        except Exception as e:
            logging.error(f"Sentiment analysis error: {e}")
        return "محايد"

    @staticmethod
    def analyze_toxicity(text: str) -> str:
        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        # نستخدم الموديل متعدد اللغات لأن الموديل السابق (toxic-bert) لا يفهم العربية
        url = "https://router.huggingface.co/models/MoritzLaurer/mDeBERTa-v3-base-mnli-xnli"
        
        # نحدد التصنيفات التي سيفهمها الموديل بالعربية
        toxic_label = "شتائم وكلام بذيء ومهين"
        safe_label = "نقد محترم وكلام عادي"

        try:
            response = requests.post(url, headers=headers, json={
                "inputs": text,
                "parameters": {
                    "candidate_labels": [toxic_label, safe_label],
                    "multi_label": False
                }
            })

            if response.status_code == 200:
                result = response.json()
                
                # استخراج النتائج (تأتي مرتبة من الأعلى للأقل)
                labels = result.get("labels", [])
                scores = result.get("scores", [])

                if labels and scores:
                    top_label = labels[0]
                    top_score = scores[0]

                    # الشرط: إذا كان التصنيف الأعلى هو "شتائم" وبنسبة ثقة أعلى من 60%
                    if top_label == toxic_label and top_score > 0.60:
                        return "toxic"
            
            elif response.status_code == 503:
                # في حالة أن الموديل قيد التحميل، نتجاوز الفحص مؤقتاً
                logging.info("Model loading, skipping toxicity check")
            else:
                logging.error(f"Toxicity API error: {response.status_code} - {response.text}")

        except Exception as e:
            logging.error(f"Toxicity analysis error: {e}")

        # الإرجاع الافتراضي نفس كودك القديم
        return "non-toxic"

    @staticmethod
    def classify_review(sentiment: str, toxicity: str, stars: int = None, text: str = "") -> str:
        """
        تصنيف نوع التقييم بناءً على المشاعر، السمية، النجوم، والنص
        """
        # تحويل الإدخالات لضمان الاتساق
        sentiment_normalized = sentiment.lower() if sentiment else "neutral"
        is_negative_sentiment = sentiment_normalized in ["سلبي", "negative", "label_0"]
        is_positive_sentiment = sentiment_normalized in ["إيجابي", "positive", "label_1"]
        is_toxic = toxicity == "toxic"

        # دمج مع النجوم إذا كانت متوفرة
        if stars is not None:
            if stars <= 2:
                is_negative_sentiment = True
                is_positive_sentiment = False
            elif stars >= 4:
                is_negative_sentiment = False
                is_positive_sentiment = True

        # تحليل النص للكشف عن كلمات دالة على الشكاوى
        complaint_keywords = [
            "سرق", "انتزع", "خدع", "غش", "زبالة", "خري", "بخرا", "ما بنصح",
            "جربان", "كذب", "غير صادق", "سيء", "رديء", "مش حلو", "مش طيب"
        ]
        has_complaint_words = any(keyword in text.lower() for keyword in complaint_keywords)

        # منطق التصنيف المحسن
        if is_negative_sentiment or has_complaint_words:
            if is_toxic or has_complaint_words:
                return "شكوى"
            else:
                return "نقد"
        elif is_positive_sentiment:
            return "إيجابي"
        else:
            # في الحالات المحايدة، اعتمد على النجوم
            if stars is not None:
                if stars <= 2:
                    return "نقد"
                elif stars >= 4:
                    return "إيجابي"
            return "إيجابي"  # افتراض إيجابي للمحايد

    @staticmethod
    def detect_review_quality(text: str, enjoy_most: str, improve_product: str, additional_feedback: str) -> dict:
        flags = []
        quality_score = 1.0
        all_text = f"{text} {enjoy_most} {improve_product} {additional_feedback}".strip()

        if not all_text or len(all_text.strip()) < 3:
            return {'quality_score': 0.0, 'flags': ['empty_content'], 'is_suspicious': True}

        try:
            arabic_chars = sum(1 for c in all_text if '\u0600' <= c <= '\u06FF')
            english_chars = sum(1 for c in all_text if c.isascii() and c.isalpha())
            total_alpha = arabic_chars + english_chars
            if total_alpha < len(all_text) * 0.3:
                flags.append('gibberish_content')
                quality_score -= 0.3
        except Exception as e:
            logging.error(f"Language detection error: {e}")
        if total_alpha > 500:  # تقييم طويل جداً قد يكون غير طبيعي
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
        """
        يكشف عن عدم تطابق المحتوى باستخدام مقارنة ذكية بين نوع المتجر وسياقات أخرى.
        """
        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        url = "https://router.huggingface.co/models/MoritzLaurer/mDeBERTa-v3-base-mnli-xnli"

        # 1. تحسين القاموس ليشمل كلمات مفتاحية أكثر دقة
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

        # الحصول على التصنيف العربي المناسب (أو استخدام نفس الكلمة إذا لم توجد في القاموس)
        target_label = shop_types_arabic.get(shop_type, shop_type)

        # 2. إضافة تصنيفات منافسة (إجبار الموديل على الاختيار)
        # هذا هو السر للدقة: نعطي الموديل خيار "تعليق عام" وخيار "شيء آخر"
        general_label = "خدمة عملاء وتعامل عام ونظافة"
        other_label = "سياق آخر غير مرتبط"

        candidate_labels = [target_label, general_label, other_label]

        payload = {
            "inputs": text,
            "parameters": {
                "candidate_labels": candidate_labels,
                "multi_label": False  # نريد مجموع النسب يساوي 100%
            }
        }

        try:
            response = requests.post(url, headers=headers, json=payload)

            # معالجة حالة "الموديل قيد التحميل" (شائعة في Hugging Face)
            if response.status_code == 503:
                logging.info("Model is loading, waiting...")
                import time
                time.sleep(20)  # انتظار التحميل
                response = requests.post(url, headers=headers, json=payload)

            if response.status_code == 200:
                result = response.json()

                # API Zero-Shot يرجع dict يحتوي على labels و scores مرتبة
                # { "labels": ["مطعم...", "خدمة...", "سياق آخر"], "scores": [0.8, 0.1, 0.1] }

                labels = result.get("labels", [])
                scores = result.get("scores", [])

                # إنشاء خريطة للنتائج ليسهل التعامل معها
                result_map = {label: score for label, score in zip(labels, scores)}

                # 3. منطق التحقق الذكي
                # نجمع نسبة "نوع المتجر" + "التعليق العام"
                target_score = result_map.get(target_label, 0)
                general_score = result_map.get(general_label, 0)
                other_score = result_map.get(other_label, 0)

                valid_relevance = target_score + general_score

                # نعتبره mismatch فقط إذا كان "سياق آخر" هو المسيطر بقوة
                # أو إذا كانت الصلة بالمتجر والعام ضعيفة جداً (أقل من 40%)
                has_mismatch = valid_relevance < 0.40

                return {
                    'mismatch_score': round(other_score, 2),  # كلما زاد هذا، زاد احتمال الخطأ
                    'confidence': round(valid_relevance * 100, 2),
                    'reasons': [f"النص يبدو بعيداً عن سياق {shop_type} أو الخدمة العامة"] if has_mismatch else [],
                    'has_mismatch': has_mismatch,
                    'predicted_label': labels[0] if labels else None  # أعلى تصنيف توقعه الموديل
                }
            else:
                logging.error(f"HF API Error: {response.status_code} - {response.text}")

        except Exception as e:
            logging.error(f"Context mismatch detection error: {e}")

        # Fallback في حالة الخطأ
        return {
            'mismatch_score': 0.0,
            'confidence': 100.0,  # نفترض حسن النية عند الخطأ التقني
            'has_mismatch': False,
            'predicted_label': "Error"
        }
