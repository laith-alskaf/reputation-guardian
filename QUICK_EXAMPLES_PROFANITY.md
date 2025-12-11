# 📝 أمثلة سريعة - خدمة الترميز

## مثال 1: كشف بسيط

```python
from app.services.external.text_profanity_service import TextProfanityService

text = "الخدمة خريا جداً"
result = TextProfanityService.detect_profanity_with_hf(text)

print(f"فيه كلام بذيء؟ {result['has_profanity']}")        # True
print(f"درجة السمية: {result['profanity_score']}")        # 0.85
```

---

## مثال 2: ترميز النص

```python
text = "الخدمة سيئة والموظفون خريا"
censored, words = TextProfanityService.censor_profanity(text)

print(f"النص الأصلي: {text}")
# الخدمة سيئة والموظفون خريا

print(f"النص المرمّز: {censored}")
# الخدمة سيئة والموظفون *****

print(f"الكلمات المرمّزة: {words}")
# ['خريا']
```

---

## مثال 3: تحليل كامل

```python
result = TextProfanityService.analyze_and_censor(
    text="كلام بذيء هنا",
    censor_char='*',
    method='word'
)

print(result)
# {
#   'original_text': 'كلام بذيء هنا',
#   'censored_text': 'كلام **** هنا',
#   'has_profanity': True,
#   'censored_words': ['بذيء'],
#   'words_count': 1,
#   'text_changed': True
# }
```

---

## مثال 4: استخدام في SentimentServiceV2

```python
from app.services.external.sentiment_service_v2 import SentimentServiceV2

result = SentimentServiceV2.detect_and_censor_profanity_in_review(
    text="الخدمة سيئة جداً",
    enjoy_most="الموظفون لطيفون",
    improve_product="الأسعار غالية",
    additional_feedback=""
)

print(f"عدد الحقول بفيها كلام بذيء: {result['summary']['total_fields_with_profanity']}")
# 1

print(f"الكلمات: {result['summary']['total_censored_words']}")
# ['سيئة'] (إذا كانت في قائمة الكلمات)
```

---

## مثال 5: طرق ترميز مختلفة

```python
text = "خدمة خريا جداً"

# الطريقة 1: ترميز كامل (افتراضي)
censored1, _ = TextProfanityService.censor_profanity(text, method='word')
print(censored1)  # خدمة ***** جداً

# الطريقة 2: إظهار الحرف الأول والأخير
censored2, _ = TextProfanityService.censor_profanity(text, method='first_last')
print(censored2)  # خدمة خ***ا جداً

# الطريقة 3: استبدال بـ emoji
censored3, _ = TextProfanityService.censor_profanity(text, method='emoji')
print(censored3)  # خدمة 🔞 جداً
```

---

## مثال 6: إحصائيات

```python
text = "خريا خريا خريا والموظفون حمير وخدمة سيئة جداً"

stats = TextProfanityService.get_profanity_stats(text)

print(f"عدد الكلمات: {stats['total_words']}")                # 8
print(f"كلمات بذيئة: {stats['profanity_count']}")            # 3 (تقريباً)
print(f"نسبة: {stats['profanity_percentage']}%")              # 37.5%
print(f"مستوى الخطورة: {stats['severity_level']}")           # severe
print(f"الكلمات المكتشفة: {stats['detected_words']}")        # ['خريا', 'حمير']
```

---

## مثال 7: في WebhookService (تلقائي)

```python
# هذا يحدث تلقائياً في webhook_service_v2.py
# عندما يُرسل تقييم

# في قاعدة البيانات ستجد:
review = {
    "email": "customer@test.com",
    "original_fields": {
        "text": "الخدمة خريا",
        ...
    },
    "profanity_check": {
        "has_any_profanity": True,
        "fields_affected": 1,
        "censored_words": ["خريا"],
        "field_details": {
            "text": {
                "has_profanity": True,
                "censored_text": "الخدمة *****",
                "censored_words": ["خريا"]
            },
            ...
        }
    }
}
```

---

## مثال 8: فحص بسيط في API

```python
@app.route('/check-profanity', methods=['POST'])
def check_profanity():
    text = request.json.get('text')
    
    result = TextProfanityService.detect_profanity_with_hf(text)
    
    return jsonify({
        'has_profanity': result['has_profanity'],
        'score': result['profanity_score'],
        'message': 'نص آمن' if not result['has_profanity'] else 'يحتوي على كلام غير مناسب'
    })

# استخدام:
# POST /check-profanity
# { "text": "الخدمة خريا" }
# Response:
# {
#   "has_profanity": true,
#   "score": 0.85,
#   "message": "يحتوي على كلام غير مناسب"
# }
```

---

## مثال 9: Regex vs HF

```python
text = "كلام بذيء"

# استخدام Regex (سريع)
regex_result = TextProfanityService._detect_profanity_with_patterns(text)
print(f"Regex: {regex_result['detected_words']}")
# الوقت: < 100ms

# استخدام HF (أدق)
hf_result = TextProfanityService.detect_profanity_with_hf(text)
print(f"HF: {hf_result['profanity_score']}")
# الوقت: 2-3 ثواني

# النتيجة قد تختلف قليلاً
```

---

## مثال 10: معالجة آمنة للنصوص الفارغة

```python
from app.services.external.sentiment_service_v2 import SentimentServiceV2

# نص فارغ
result = SentimentServiceV2.detect_and_censor_profanity_in_review(
    text="",
    enjoy_most="",
    improve_product="",
    additional_feedback=""
)

print(result['summary']['has_any_profanity'])  # False
print(result['summary']['total_censored_words'])  # []
# لا يوجد أخطاء!
```

---

## ملخص سريع

| المهمة | الدالة | الوقت |
|--------|--------|-------|
| كشف فقط | `detect_profanity_with_hf()` | 2-3s |
| كشف سريع | `_detect_profanity_with_patterns()` | <100ms |
| ترميز فقط | `censor_profanity()` | <50ms |
| الكل معاً | `analyze_and_censor()` | 2-3s |
| في التقييم | `detect_and_censor_profanity_in_review()` | 2-3s |
| إحصائيات | `get_profanity_stats()` | <100ms |

---

## 🎯 ملاحظات مهمة

- ✅ جميع الدوال تتعامل مع النصوص الفارغة
- ✅ استخدم `use_hf=False` للسرعة
- ✅ استخدم `use_hf=True` للدقة
- ✅ يمكن تغيير الكلمات في `PROFANITY_PATTERNS`
- ✅ ثلاث طرق ترميز متاحة

**ابدأ باستخدام الأمثلة البسيطة أولاً!** 🚀
