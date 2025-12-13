import requests
import re
import logging
from typing import Dict, List, Tuple
from app.presentation.config import HF_TOKEN, HF_TOXICITY_MODEL_URL

class TextProfanityService:
    
    PROFANITY_PATTERNS = {
        'arabic_street': [
            r'شتم|شتيم|شتمت|تشتيم',
            r'كس|كسخ|كسك|كسكي',
            r'خرا|خرى|خري',
            r'طيز|كيز|زقر',
            r'حول|حيول|حمار',
            r'غبي|أغبياء|أحمق',
            r'زنا|زاني',
            r'جنس|نيك|ينيك',
            r'يلعن|يلحس|يسخ',
            r'ولد|بنت|حرام',
        ],
        'arabic_classical': [
            r'سفيه|سفهاء',
            r'فاجر|فجرة',
            r'كافر|كفرة',
            r'ملحد|ملحدين',
        ],
        'english': [
            r'\bf[*u]ck|\bsh[*i]t|\bass\b',
            r'\bdamn\b|\bhell\b|\bcrap\b',
            r'\bitch\b|\bstupid\b|\basshole\b',
            r'\bgoddamn\b|\bgoddamned\b',
            r'\bb[*i]tch\b|\bwhore\b|\bslut\b',
        ],
        'common_abbreviations': [
            r'f\*ck|f\*\*k|fck',
            r'sh\*t|sh\*\*t|sht',
            r'b\*tch|b\*\*ch|btch',
        ]
    }

    @staticmethod
    def detect_profanity_with_hf(text: str, confidence_threshold: float = 0.6) -> Dict:
        if not text or not text.strip():
            return {
                'has_profanity': False,
                'profanity_score': 0.0,
                'confidence': 0.0,
                'detected_words': [],
                'method': 'empty_text'
            }

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

                    has_profanity = (top_label == toxic_label and top_score >= confidence_threshold)

                    return {
                        'has_profanity': has_profanity,
                        'profanity_score': round(top_score, 3),
                        'confidence': round(1 - top_score, 3) if not has_profanity else round(top_score, 3),
                        'detected_words': [],
                        'method': 'huggingface_zero_shot'
                    }

            elif response.status_code == 503:
                logging.info("HF model loading, using fallback pattern matching")
                return TextProfanityService._detect_profanity_with_patterns(text)
            else:
                logging.error(f"HF API error: {response.status_code}")
                return TextProfanityService._detect_profanity_with_patterns(text)

        except Exception as e:
            logging.error(f"Profanity detection error: {e}")
            return TextProfanityService._detect_profanity_with_patterns(text)

    @staticmethod
    def _detect_profanity_with_patterns(text: str) -> Dict:
        detected_words = []
        max_score = 0.0

        text_lower = text.lower()

        for category, patterns in TextProfanityService.PROFANITY_PATTERNS.items():
            for pattern in patterns:
                matches = re.findall(pattern, text_lower)
                if matches:
                    detected_words.extend(matches)
                    category_score = 0.7 if category == 'arabic_street' else 0.6
                    max_score = max(max_score, category_score)

        has_profanity = len(detected_words) > 0

        return {
            'has_profanity': has_profanity,
            'profanity_score': round(max_score, 3),
            'confidence': 0.5,
            'detected_words': list(set(detected_words)),
            'method': 'regex_patterns'
        }

    @staticmethod
    def censor_profanity(text: str, censor_char: str = '*', method: str = 'word') -> Tuple[str, List[str]]:
        if not text or not text.strip():
            return text, []

        censored_text = text
        censored_words = []

        for category, patterns in TextProfanityService.PROFANITY_PATTERNS.items():
            for pattern in patterns:
                matches = re.finditer(pattern, censored_text, re.IGNORECASE)
                
                for match in matches:
                    original_word = match.group(0)
                    censored_words.append(original_word)

                    if method == 'word':
                        replacement = censor_char * len(original_word)
                    elif method == 'first_last':
                        if len(original_word) <= 2:
                            replacement = censor_char * len(original_word)
                        else:
                            replacement = original_word[0] + censor_char * (len(original_word) - 2) + original_word[-1]
                    elif method == 'emoji':
                        replacement = '🔞'
                    else:
                        replacement = censor_char * len(original_word)

                    censored_text = re.sub(
                        r'\b' + re.escape(original_word) + r'\b',
                        replacement,
                        censored_text,
                        flags=re.IGNORECASE
                    )

        return censored_text, list(set(censored_words))

    @staticmethod
    def analyze_and_censor(text: str, censor_char: str = '*', method: str = 'word', use_hf: bool = True) -> Dict:
        if not text or not text.strip():
            return {
                'original_text': text,
                'censored_text': text,
                'has_profanity': False,
                'profanity_details': {
                    'has_profanity': False,
                    'profanity_score': 0.0,
                    'confidence': 0.0,
                    'detected_words': [],
                    'method': 'empty_text'
                },
                'censored_words': [],
                'censoring_method': method
            }

        if use_hf:
            profanity_details = TextProfanityService.detect_profanity_with_hf(text)
        else:
            profanity_details = TextProfanityService._detect_profanity_with_patterns(text)

        censored_text, censored_words = TextProfanityService.censor_profanity(
            text,
            censor_char=censor_char,
            method=method
        )

        return {
            'original_text': text,
            'censored_text': censored_text,
            'has_profanity': profanity_details['has_profanity'],
            'profanity_details': profanity_details,
            'censored_words': censored_words,
            'censoring_method': method,
            'words_count': len(censored_words),
            'text_changed': censored_text != text
        }

    @staticmethod
    def censor_review_fields(enjoy_most: str = "", improve_product: str = "", 
                            additional_feedback: str = "", censor_char: str = '*') -> Dict:
        result = {
            'enjoy_most': {
                'original': enjoy_most,
                'censored': "",
                'has_profanity': False,
                'censored_words': []
            },
            'improve_product': {
                'original': improve_product,
                'censored': "",
                'has_profanity': False,
                'censored_words': []
            },
            'additional_feedback': {
                'original': additional_feedback,
                'censored': "",
                'has_profanity': False,
                'censored_words': []
            },
            'total_censored_words': []
        }

        fields_data = [
            ('enjoy_most', enjoy_most),
            ('improve_product', improve_product),
            ('additional_feedback', additional_feedback)
        ]

        for field_name, field_text in fields_data:
            if field_text and field_text.strip():
                analysis = TextProfanityService.analyze_and_censor(
                    field_text,
                    censor_char=censor_char,
                    method='word',
                    use_hf=False
                )

                result[field_name]['censored'] = analysis['censored_text']
                result[field_name]['has_profanity'] = analysis['has_profanity']
                result[field_name]['censored_words'] = analysis['censored_words']
                result['total_censored_words'].extend(analysis['censored_words'])

        result['total_censored_words'] = list(set(result['total_censored_words']))
        result['has_any_profanity'] = any([
            result['enjoy_most']['has_profanity'],
            result['improve_product']['has_profanity'],
            result['additional_feedback']['has_profanity']
        ])

        return result

    @staticmethod
    def get_profanity_stats(text: str) -> Dict:
        if not text or not text.strip():
            return {
                'total_words': 0,
                'profanity_count': 0,
                'profanity_percentage': 0.0,
                'severity_level': 'clean'
            }

        profanity_result = TextProfanityService._detect_profanity_with_patterns(text)
        words = text.split()
        total_words = len(words)
        profanity_count = len(profanity_result['detected_words'])

        if total_words == 0:
            profanity_percentage = 0.0
        else:
            profanity_percentage = (profanity_count / total_words) * 100

        if profanity_percentage == 0:
            severity_level = 'clean'
        elif profanity_percentage < 5:
            severity_level = 'mild'
        elif profanity_percentage < 15:
            severity_level = 'moderate'
        else:
            severity_level = 'severe'

        return {
            'total_words': total_words,
            'profanity_count': profanity_count,
            'profanity_percentage': round(profanity_percentage, 2),
            'severity_level': severity_level,
            'detected_words': profanity_result['detected_words']
        }
