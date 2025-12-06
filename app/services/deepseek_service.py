import requests
from app.config import HF_TOKEN
import re
from app.services.sentiment_service import clean_text

def organize_customer_feedback(enjoy_most, improve_product, additional_feedback):
    """
    استخدام DeepSeek لتنظيم وإعادة كتابة إجابات العميل بطريقة منظمة وموحدة
    """
    headers = {"Authorization": f"Bearer {HF_TOKEN}"}
    url = "https://router.huggingface.co/v1/chat/completions"

    # تنظيف النصوص أولاً
    enjoy_most_clean = clean_text(enjoy_most)
    improve_product_clean = clean_text(improve_product)
    additional_feedback_clean = clean_text(additional_feedback)

    # بناء prompt لتنظيم الحقول فقط
    prompt = f"""
    قم بتنظيم وإعادة كتابة إجابات العميل التالية بطريقة منظمة وواضحة باللغة العربية.
    لا تقم بإضافة معلومات جديدة أو حذف أي تفاصيل مهمة. فقط نظم وأعد صياغة النصوص بطريقة احترافية:
    اريد الاجابة تكون نفس هذه بالضبط لاتضيف ولا تنقص:

    1. ما يستمتع به العميل أكثر: "{enjoy_most_clean}"
    2. اقتراحات تحسين المنتج: "{improve_product_clean}"
    3. ملاحظات إضافية: "{additional_feedback_clean}"

    المطلوب:
    - أعد كتابة كل قسم بطريقة منظمة وموجزة
    - احتفظ بجميع التفاصيل الأصلية
    - استخدم لغة واضحة ومهنية
    - إذا كان القسم فارغًا، اكتب "لم يتم تقديم إجابة"
    لا تجيب غير يلي مطلوب منك
    """

    try:
        response = requests.post(url, headers=headers, json={
            "messages": [
        {
            "role": "user",
            "content":prompt
        }
    ],
            "model": "deepseek-ai/DeepSeek-V3.2-Exp:novita"
        })

        if response.status_code == 200:
            result = response.json()["choices"][0]["message"]["content"]
            print(result)
            if result:
                return result
        return "لا يمكن تنظيم البيانات في الوقت الحالي"

    except requests.exceptions.RequestException as e:
        print(f"DeepSeek API error: {e}")
        return "خطأ في الاتصال بخدمة التنظيم"

def determine_overall_sentiment(stars, text, improve_product, additional_feedback):
    """
    تحديد المشاعر العامة بناءً على النجوم والنصوص
    """
    # تحليل النجوم
    if stars >= 4:
        star_sentiment = "إيجابي"
    elif stars >= 3:
        star_sentiment = "محايد"
    else:
        star_sentiment = "سلبي"

    # تحليل النصوص للكشف عن مشاعر سلبية
    negative_keywords = ["سيء", "بطيء", "غير مرضي", "مشكلة", "سوء", "ضعيف", "لا أحب", "أفضل لو"]
    text_combined = f"{text} {improve_product} {additional_feedback}".lower()

    has_negative = any(keyword in text_combined for keyword in negative_keywords)
    has_improvements = len(improve_product.strip()) > 0

    if star_sentiment == "سلبي" or has_negative or has_improvements:
        return "سلبي"
    elif star_sentiment == "محايد":
        return "محايد"
    else:
        return "إيجابي"

if __name__ == "__main__":
    # Test
    summary = analyze_and_summarize_review(
        email="test@example.com",
        stars=3,
        text="الخدمة جيدة لكن يمكن تحسين السرعة",
        enjoy_most="الجودة العالية",
        improve_product="زيادة السرعة في التوصيل",
        additional_feedback="الأسعار مناسبة",
        shop_type="مطعم"
    )
    print("Analysis result:", summary)
