# 🚀 دليل الاستخدام السريع - V2

## 📁 الملفات الجديدة

```
backend/app/
├── dto/
│   └── sentiment_analysis_result_dto.py          🆕 DTO جديد
├── services/
│   ├── external/
│   │   ├── sentiment_service_v2.py              🆕 التحليل الأولي
│   │   └── deepseek_service_v2.py               🆕 المعالجة الذكية
│   └── core/
│       └── webhook_service_v2.py                🆕 الخدمة الأساسية
```

---

## 1️⃣ استخدام في WebhookController

```python
from flask import Blueprint, request
from app.services.core.webhook_service_v2 import WebhookServiceV2  # 🆕 V2
from app.utils.response import ResponseBuilder
from app.dto.review_dto import ReviewDTO
import logging

webhook_bp = Blueprint('webhook', __name__)
webhook_service = WebhookServiceV2()  # 🆕 استخدام V2

@webhook_bp.route('/webhook', methods=['POST'])
def webhook():
    try:
        data = request.json or {}
        dto = ReviewDTO.from_dict(data)
        
        result = webhook_service.process_review(dto)
        return ResponseBuilder.success(result, "تم حفظ التقييم بنجاح", 200)

    except ValueError as e:
        logging.warning(f"Validation error: {e}")
        return ResponseBuilder.error(str(e), 400)
    except LookupError as e:
        logging.warning(f"Duplicate or not found: {e}")
        return ResponseBuilder.error(str(e), 400)
    except Exception as e:
        logging.error(f"Webhook error: {e}", exc_info=True)
        return ResponseBuilder.error("Internal server error", 500)
```

---

## 2️⃣ استخدام في Dashboards/Reports

إذا أردت الوصول لنتائج التحليل الأولي:

```python
from app.services.external.sentiment_service_v2 import SentimentServiceV2
from app.dto.review_dto import ReviewDTO

svc = SentimentServiceV2()
result = svc.analyze_review_comprehensive(dto, shop_type="مطعم")

print(f"المشاعر: {result.sentiment}")           # "إيجابي", "سلبي", "محايد"
print(f"السمية: {result.toxicity}")             # "toxic", "uncertain", "non-toxic"
print(f"النوع: {result.category}")              # "شكوى", "نقد", "إيجابي"
print(f"الجودة: {result.quality_score}")        # 0.0-1.0
print(f"Spam: {result.is_spam}")                # true/false
print(f"السياق: {result.context_match}")        # true/false
print(f"علامات: {result.quality_flags}")        # ["empty_content", ...]
```

---

## 3️⃣ استخدام Deep Analysis

إذا أردت الحصول على الرد والحلول:

```python
from app.services.external.sentiment_service_v2 import SentimentServiceV2
from app.services.external.deepseek_service_v2 import DeepSeekServiceV2
from app.dto.review_dto import ReviewDTO

sentiment_svc = SentimentServiceV2()
deepseek_svc = DeepSeekServiceV2()

# المرحلة 1: التحليل الأولي
sentiment_result = sentiment_svc.analyze_review_comprehensive(dto, "مطعم")

# المرحلة 2: المعالجة الذكية
if not sentiment_result.is_spam:  # تخطي الـ spam
    analysis = deepseek_svc.format_insights_and_reply(
        dto=dto,
        sentiment_result=sentiment_result,
        shop_type="مطعم"
    )
    
    print(f"الملخص: {analysis.summary}")
    print(f"المواضيع: {analysis.key_themes}")
    print(f"الحلول: {analysis.actionable_insights}")
    print(f"الرد: {analysis.suggested_reply}")
```

---

## 📊 نموذج البيانات

### Input: ReviewDTO
```python
{
    "email": "customer@email.com",
    "phone": "+201234567890",
    "shop_id": "shop123",
    "shop_name": "اسم المتجر",
    "stars": 5,
    "text": "التقييم الرئيسي",
    "enjoy_most": "ما أعجبني",
    "improve_product": "ما يمكن تحسينه",
    "additional_feedback": "ملاحظات إضافية"
}
```

### Output Phase 1: SentimentAnalysisResultDTO
```python
{
    "sentiment": "إيجابي",                  # الشعور العام
    "toxicity": "non-toxic",               # السمية
    "category": "إيجابي",                   # النوع
    "quality_score": 0.95,                 # درجة الجودة (0-1)
    "is_spam": False,                      # هل هو spam؟
    "context_match": True,                 # هل يتطابق مع نوع المتجر؟
    "quality_flags": [],                   # أسباب أي مشاكل بالجودة
    "mismatch_reasons": []                 # أسباب عدم التطابق
}
```

### Output Phase 2: AnalysisResultDTO
```python
{
    "sentiment": "إيجابي",
    "category": "إيجابي",
    "summary": "العميل راضي جداً عن الخدمة",
    "key_themes": ["الجودة", "الخدمة", "السعر"],
    "actionable_insights": [
        "الاستمرار في نفس مستوى الجودة",
        "الاهتمام بالعملاء المميزين"
    ],
    "suggested_reply": "شكراً جزيلاً على تقييمك الرائع...",
    "quality_score": 0.95,
    "is_spam": False,
    "context_match": True
}
```

### Output Final: review_data (في DB)
```python
{
    "email": "customer@email.com",
    "phone": "+201234567890",
    "shop_id": "shop123",
    "stars": 5,
    
    # من Phase 1
    "overall_sentiment": "إيجابي",
    "toxicity": "non-toxic",
    "quality_score": 0.95,
    "quality_flags": [],
    
    # من Phase 2
    "summary": "العميل راضي جداً عن الخدمة",
    "organized_feedback": "📝 الملخص: ...\n🏷️ المواضيع: ...",
    "solutions": "- الاستمرار في نفس المستوى\n- الاهتمام بالعملاء",
    "suggested_reply": "شكراً جزيلاً على تقييمك...",
    
    # Meta
    "category": "إيجابي",
    "is_spam": False,
    "context_match": True,
    
    # Original
    "original_fields": {
        "text": "التقييم الرئيسي",
        "enjoy_most": "ما أعجبني",
        ...
    }
}
```

---

## ⚡ Performance Notes

| العملية | الوقت المتوقع | التكلفة (Tokens) |
|---------|---|---|
| Text cleaning | < 100ms | 0 |
| Sentiment analysis (HF) | 2-3s | ~50 |
| Toxicity analysis (HF) | 2-3s | ~50 |
| Classification | < 100ms | 0 |
| Quality detection | < 200ms | 0 |
| Context mismatch (HF) | 3-5s | ~100 |
| **المرحلة 1 الإجمالية** | **7-12s** | **~200** |
| Deep insights (DeepSeek) | 8-15s | ~500 |
| **المجموع الكلي** | **15-27s** | **~700** |

---

## 🔐 معالجة الأخطاء

### حالة 1: API DeepSeek معطل
```python
# DeepSeekServiceV2 يرجع fallback تلقائياً
suggested_reply = "شكراً جزيلاً لك على تقييمك القيم. نحن نقدر ملاحظاتك..."
```

### حالة 2: نص فارغ
```python
# SentimentServiceV2 يرجع:
{
    "sentiment": "محايد",
    "quality_score": 0.0,
    "is_spam": True,
    "quality_flags": ["empty_content"]
}
# DeepSeekServiceV2 لن يتم استدعاؤه
```

### حالة 3: HF API معطل
```python
# اعتماد على sentiment/toxicity الافتراضي
sentiment = "محايد"
toxicity = "non-toxic"
```

---

## 🧪 اختبار سريع

```python
from app.dto.review_dto import ReviewDTO
from app.services.core.webhook_service_v2 import WebhookServiceV2

# بيانات اختبار
data = {
    "data": {
        "fields": [
            {"label": "email", "value": "test@test.com"},
            {"label": "shop_id", "value": "shop1"},
            {"label": "shop_name", "value": "مطعم التجربة"},
            {"label": "text", "value": "الخدمة رائعة جداً"},
            {"label": "stars", "value": "5"},
            {"label": "enjoy_most", "value": "جودة الطعام"},
            {"label": "improve_product", "value": ""},
            {"label": "additional_feedback", "value": ""}
        ]
    }
}

dto = ReviewDTO.from_dict(data)
service = WebhookServiceV2()
result = service.process_review(dto)
print(result)  # {"review_id": "..."}
```

---

## 📝 ملاحظات مهمة

- ✅ **الملفات القديمة**: لا تحتاج لحذفها، يمكن الاحتفاظ بها للمرجعية
- ✅ **التوافقية**: V2 لا تعتمد على الملفات القديمة
- ✅ **التوسع المستقبلي**: يمكن إضافة v3 بنفس النمط
- ✅ **قاعدة البيانات**: لا حاجة لتعديل schema
- ⚠️ **الاختبار**: تأكد من وجود HF tokens صحيحة في .env
