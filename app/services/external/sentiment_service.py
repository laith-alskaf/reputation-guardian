import requests
import re
import unicodedata
import logging
from app.config import HF_TOKEN
from app.services_interfaces import ISentimentService

class SentimentService(ISentimentService):
    def clean_text(self, text: str) -> str:
        try:
            text = unicodedata.normalize('NFKC', text)
            text = re.sub(r'[^\u0600-\u06FF\s]', '', text).strip()
            return text
        except Exception as e:
            logging.error(f"Error cleaning text: {e}")
            return text

    def analyze_sentiment(self, text: str) -> str:
        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        url = "https://api-inference.huggingface.co/models/CAMeL-Lab/bert-base-arabic-camelbert-da-sentiment"
        try:
            response = requests.post(url, headers=headers, json={"inputs": text})
            if response.status_code == 200:
                result = response.json()
                if isinstance(result, list) and result:
                    return result[0]['label']
        except Exception as e:
            logging.error(f"Sentiment analysis error: {e}")
        return "neutral"

    def analyze_toxicity(self, text: str) -> str:
        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        url = "https://api-inference.huggingface.co/models/unitary/toxic-bert"
        try:
            response = requests.post(url, headers=headers, json={"inputs": text})
            if response.status_code == 200:
                result = response.json()
                if isinstance(result, list) and result:
                    return result[0]['label']
        except Exception as e:
            logging.error(f"Toxicity analysis error: {e}")
        return "non-toxic"

    def classify_review(self, sentiment: str, toxicity: str) -> str:
        if sentiment in ['negative', 'LABEL_0'] and toxicity == 'toxic':
            return 'شكوى'
        elif sentiment in ['negative', 'LABEL_0']:
            return 'نقد'
        else:
            return 'إيجابي'

    def detect_review_quality(self, text: str, enjoy_most: str, improve_product: str, additional_feedback: str) -> dict:
        flags = []
        quality_score = 1.0
        all_text = f"{text} {enjoy_most} {improve_product} {additional_feedback}".strip()

        if not all_text:
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

        if re.search(r'(.)\1{4,}', all_text):
            flags.append('repetitive_characters')
            quality_score -= 0.2

        special_chars = sum(1 for c in all_text if not c.isalnum() and not c.isspace() and c not in '.,!?؛،')
        if special_chars > len(all_text) * 0.2:
            flags.append('excessive_special_chars')
            quality_score -= 0.2

        toxicity_score = self.analyze_toxicity(all_text)
        if toxicity_score in ['toxic', 'LABEL_1']:
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