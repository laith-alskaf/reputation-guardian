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
        url = "https://router.huggingface.co/models/unitary/toxic-bert"
        try:
            response = requests.post(url, headers=headers, json={"inputs": text})
            if response.status_code == 200:
                result = response.json()
                if isinstance(result, list) and result:
                    label = result[0].get("label", "non-toxic")
                    return "toxic" if label in ["toxic", "label_1"] else "non-toxic"
            else:
                logging.error(f"HuggingFace Toxicity API error: {response.status_code} - {response.text}")
        except Exception as e:
            logging.error(f"Toxicity analysis error: {e}")
        return "non-toxic"

    @staticmethod
    def classify_review(sentiment: str, toxicity: str) -> str:
        # توحيد المنطق: سواء رجع الموديل "سلبي" أو "LABEL_0" نعتبرها سلبية
        if sentiment in ["سلبي", "negative", "label_0"] and toxicity == "toxic":
            return "شكوى"
        elif sentiment in ["سلبي", "negative", "label_0"]:
            return "نقد"
        else:
            return "إيجابي"

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