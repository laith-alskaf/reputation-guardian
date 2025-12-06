import requests
import re
import unicodedata
from config import HF_TOKEN

def clean_text(text):
    """
    Clean Arabic text: normalize, remove non-Arabic characters, strip.
    """
    text = unicodedata.normalize('NFKC', text)
    text = re.sub(r'[^\u0600-\u06FF\s]', '', text).strip()
    return text

def analyze_sentiment(text):
    """
    Analyze sentiment using CAMeL-Lab BERT model.
    """
    headers = {"Authorization": f"Bearer {HF_TOKEN}"}
    url = "https://api-inference.huggingface.co/models/CAMeL-Lab/bert-base-arabic-camelbert-da-sentiment"
    response = requests.post(url, headers=headers, json={"inputs": text})
    if response.status_code == 200:
        result = response.json()
        if isinstance(result, list) and result:
            return result[0]['label']
    return "neutral"  # fallback

def analyze_toxicity(text):
    """
    Analyze toxicity using unitary/toxic-bert.
    """
    headers = {"Authorization": f"Bearer {HF_TOKEN}"}
    url = "https://api-inference.huggingface.co/models/unitary/toxic-bert"
    response = requests.post(url, headers=headers, json={"inputs": text})
    if response.status_code == 200:
        result = response.json()
        if isinstance(result, list) and result:
            return result[0]['label']
    return "non-toxic"  # fallback

def classify_shop_type(text):
    """
    Classify shop type based on keywords in text.
    """
    text_lower = text.lower()
    if 'طعام' in text_lower or 'مطعم' in text_lower or 'أكل' in text_lower:
        return 'مطعم'
    elif 'إلكترونيات' in text_lower or 'هاتف' in text_lower or 'كمبيوتر' in text_lower:
        return 'متجر إلكترونيات'
    elif 'ملابس' in text_lower or 'فستان' in text_lower:
        return 'متجر ملابس'
    else:
        return 'غير محدد'

def classify_review(sentiment, toxicity):
    """
    Classify review type based on sentiment and toxicity.
    """
    if sentiment in ['negative', 'LABEL_0'] and toxicity == 'toxic':
        return 'شكوى'
    elif sentiment in ['negative', 'LABEL_0']:
        return 'نقد'
    else:
        return 'إيجابي'

def detect_review_quality(text, enjoy_most, improve_product, additional_feedback):
    """
    Detect if review content is genuine and useful or spam/sarcastic.
    Uses multilingual models for Arabic/English content.
    Returns: {'quality_score': 0-1, 'flags': [], 'is_suspicious': bool}
    """
    flags = []
    quality_score = 1.0  # Start with high quality

    # Combine all text for analysis
    all_text = f"{text} {enjoy_most} {improve_product} {additional_feedback}".strip()

    if not all_text:
        return {'quality_score': 0.0, 'flags': ['empty_content'], 'is_suspicious': True}

    # 1. Check for gibberish/random text using language detection
    try:
        # Use a simple heuristic: check for Arabic/English characters ratio
        arabic_chars = sum(1 for c in all_text if '\u0600' <= c <= '\u06FF')
        english_chars = sum(1 for c in all_text if c.isascii() and c.isalpha())
        total_alpha = arabic_chars + english_chars

        if total_alpha < len(all_text) * 0.3:  # Less than 30% alphabetic characters
            flags.append('gibberish_content')
            quality_score -= 0.3
    except:
        pass

    # 2. Check for repetitive characters (e.g., "aaaaa", "ههههه")
    import re
    if re.search(r'(.)\1{4,}', all_text):  # 5 or more repeated characters
        flags.append('repetitive_characters')
        quality_score -= 0.2

    # 3. Check for spam-like content (too many special characters, URLs, etc.)
    special_chars = sum(1 for c in all_text if not c.isalnum() and not c.isspace() and c not in '.,!?؛،')
    if special_chars > len(all_text) * 0.2:  # More than 20% special characters
        flags.append('excessive_special_chars')
        quality_score -= 0.2

    # 4. Check for sarcasm/toxicity using existing models
    toxicity_score = analyze_toxicity(all_text)
    if toxicity_score in ['toxic', 'LABEL_1']:
        flags.append('high_toxicity')
        quality_score -= 0.4

    # 5. Check for very short content (but not too short as per user request)
    words = all_text.split()
    if len(words) < 2:  # Less than 2 words
        flags.append('too_short')
        quality_score -= 0.1

    # 6. Check for copy-paste content (same text multiple times)
    if len(set(words)) < len(words) * 0.5:  # Less than 50% unique words
        flags.append('repetitive_words')
        quality_score -= 0.2

    # Ensure score doesn't go below 0
    quality_score = max(0, quality_score)

    return {
        'quality_score': round(quality_score, 2),
        'flags': flags,
        'is_suspicious': quality_score < 0.5 or len(flags) > 2
    }

if __name__ == "__main__":
    # Test
    test_text = "الخدمة بطيئة"
    cleaned = clean_text(test_text)
    sent = analyze_sentiment(cleaned)
    tox = analyze_toxicity(cleaned)
    review_type = classify_review(sent, tox)
    print(f"Text: {test_text}, Cleaned: {cleaned}, Sentiment: {sent}, Toxicity: {tox}, Type: {review_type}")
