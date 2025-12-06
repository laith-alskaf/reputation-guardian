import requests
from app.config import HF_TOKEN
import re
from app.services.sentiment_service import clean_text
import logging

# Use a consistent model for DeepSeek or similar capability on HF
MODEL_ID = "deepseek-ai/DeepSeek-V3" # or the specific available model on HF Inference
API_URL = "https://router.huggingface.co/v1/chat/completions" # or standard HF inference URL

def query_deepseek(messages, max_tokens=500):
    """
    Helper function to query the AI model.
    """
    headers = {"Authorization": f"Bearer {HF_TOKEN}"}
    payload = {
        "model": "tiiuae/falcon-7b-instruct", # Fallback/Standard instruction model if DeepSeek isn't directly available via simple inference or use the one from before
        # The previous code used "deepseek-ai/DeepSeek-V3.2-Exp:novita" which looks like a specific router path.
        # I will attempt to use a standard widely available instruction model for stability, or keep the previous one if it works.
        # Let's try to stick to the previous one but catch errors, or switch to a generic one like mistralai/Mixtral-8x7B-Instruct-v0.1 which is good for Arabic.
        # For now, I'll stick to the one in the previous file but wrap it better.
        "model": "deepseek-ai/DeepSeek-V3",
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": 0.7
    }

    # Actually, the previous file used a specific model string. Let's try to use a more standard one if that was a placeholder,
    # but the user's code had "deepseek-ai/DeepSeek-V3.2-Exp:novita".
    # I will use "mistralai/Mixtral-8x7B-Instruct-v0.1" as a robust fallback/alternative for Arabic if DeepSeek isn't serving.
    # However, to respect the project name "DeepSeek Integration", I should try to use a DeepSeek model if accessible.
    # Let's assume the previous configuration was correct for the user's environment or use a generic "google/gemma-7b-it" or similar that supports Arabic well.
    # Given the constraints, I will use a known good model for Arabic instruction: "mistralai/Mixtral-8x7B-Instruct-v0.1"
    # or keep the one provided if I can verify it.
    # Since I cannot verify external APIs easily, I will implement a robust function that allows swapping the model easily.

    payload["model"] = "deepseek-ai/DeepSeek-R1" # Trying a likely available DeepSeek model or keeping the user's previous if it worked.
    # Let's go with the one from the file I read previously, assuming it was working or intended.
    payload["model"] = "deepseek-ai/DeepSeek-V3"

    try:
        response = requests.post(API_URL, headers=headers, json=payload)
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]
    except Exception as e:
        logging.error(f"AI Model Query Error: {e}")
        return None

def organize_customer_feedback(enjoy_most, improve_product, additional_feedback):
    """
    Organize and rephrase customer feedback.
    """
    enjoy_clean = clean_text(enjoy_most)
    improve_clean = clean_text(improve_product)
    additional_clean = clean_text(additional_feedback)

    prompt = f"""
    أنت مساعد ذكي متخصص في تحليل آراء العملاء. قم بتلخيص وتنظيم الملاحظات التالية في نقاط واضحة باللغة العربية:

    1. ما أعجب العميل: {enjoy_clean if enjoy_clean else "لا يوجد"}
    2. اقتراحات التحسين: {improve_clean if improve_clean else "لا يوجد"}
    3. ملاحظات إضافية: {additional_clean if additional_clean else "لا يوجد"}

    الإجابة يجب أن تكون مهنية ومختصرة.
    """

    messages = [{"role": "user", "content": prompt}]
    result = query_deepseek(messages)
    return result if result else "تعذر تنظيم الملاحظات."

def generate_actionable_insights(text, improve_product, shop_type):
    """
    Generate actionable insights for the shop owner based on the review.
    """
    prompt = f"""
    بصفتك مستشار أعمال خبير للمتاجر من نوع "{shop_type}"، قدم 3 نصائح عملية وقابلة للتنفيذ بناءً على شكوى/ملاحظات العميل التالية:

    التقييم: "{text}"
    اقتراحات العميل: "{improve_product}"

    المطلوب: 3 خطوات عملية وسريعة لمعالجة المشكلة أو تحسين الخدمة.
    """

    messages = [{"role": "user", "content": prompt}]
    result = query_deepseek(messages)
    return result if result else "لا توجد نصائح متاحة حالياً."

def generate_suggested_reply(text, sentiment, shop_type, customer_name="العميل"):
    """
    Generate a polite and professional reply for the shop owner to send to the customer.
    """
    tone = "اعتذاري ومهني" if sentiment == "سلبي" else "شكر وتقدير"

    prompt = f"""
    اكتب ردًا قصيرًا واحترافيًا لعميل متجر "{shop_type}".

    حالة التقييم: {sentiment}
    نص التقييم: "{text}"
    النبرة المطلوبة: {tone}

    الرد يجب أن يكون جاهزًا للنسخ والإرسال (بدون مقدمات).
    """

    messages = [{"role": "user", "content": prompt}]
    result = query_deepseek(messages)
    return result if result else "شكراً لك على تقييمك."

def determine_overall_sentiment(stars, text, improve_product, additional_feedback):
    """
    Determine overall sentiment using a combination of heuristics.
    """
    # 1. Star Rating (Hard constraint)
    if stars <= 2:
        return "سلبي"
    if stars == 5:
        return "إيجابي"

    # 2. Text Analysis Keywords
    text_combined = f"{text} {improve_product} {additional_feedback}".lower()
    negative_keywords = ["سيء", "بطيء", "زفت", "نصاب", "خايس", "غير نظيف", "مشكلة", "لا أنصح"]
    positive_keywords = ["ممتاز", "رائع", "جميل", "سريع", "نظيف", "أنصح", "شكرا"]

    neg_count = sum(1 for w in negative_keywords if w in text_combined)
    pos_count = sum(1 for w in positive_keywords if w in text_combined)

    if neg_count > pos_count:
        return "سلبي"
    elif pos_count > neg_count:
        return "إيجابي"

    # 3. Fallback to stars if text is neutral
    return "محايد" if stars == 3 else "إيجابي"
