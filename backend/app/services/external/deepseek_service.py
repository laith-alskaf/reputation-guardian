import requests
import logging
from app.config import HF_TOKEN
from .sentiment_service import SentimentService
from app.services_interfaces import IDeepSeekService
import os
from app.config import MODEL_ID, API_URL


class DeepSeekService(IDeepSeekService):
    def __init__(self):
        self.headers = {"Authorization": f"Bearer {HF_TOKEN}"}

    def query_deepseek(self, messages, max_tokens=500):
        payload = {
            "model": MODEL_ID,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": 0.7
        }
        try:
            response = requests.post(API_URL, headers=self.headers, json=payload)
            response.raise_for_status()
            return response.json()["choices"][0]["message"]["content"]
        except Exception as e:
            logging.error(f"AI Model Query Error: {e}")
            return None

    def organize_customer_feedback(self, enjoy_most, improve_product, additional_feedback):
        enjoy_clean = SentimentService.clean_text(enjoy_most)
        improve_clean = SentimentService.clean_text(improve_product)
        additional_clean = SentimentService.clean_text(additional_feedback)

        prompt = f"""
        أنت مساعد ذكي متخصص في تحليل آراء العملاء. قم بتلخيص وتنظيم الملاحظات التالية في نقاط واضحة باللغة العربية:

        1. ما أعجب العميل: {enjoy_clean if enjoy_clean else "لا يوجد"}
        2. اقتراحات التحسين: {improve_clean if improve_clean else "لا يوجد"}
        3. ملاحظات إضافية: {additional_clean if additional_clean else "لا يوجد"}

        الإجابة يجب أن تكون مهنية ومختصرة.
        """
        messages = [{"role": "user", "content": prompt}]
        result = self.query_deepseek(messages)
        return result if result else "تعذر تنظيم الملاحظات."

    def generate_actionable_insights(self, text, improve_product, shop_type):
        prompt = f"""
        بصفتك مستشار أعمال خبير للمتاجر من نوع "{shop_type}"، قدم 3 نصائح عملية وقابلة للتنفيذ بناءً على شكوى/ملاحظات العميل التالية:

        التقييم: "{text}"
        اقتراحات العميل: "{improve_product}"

        المطلوب: 3 خطوات عملية وسريعة لمعالجة المشكلة أو تحسين الخدمة.
        """
        messages = [{"role": "user", "content": prompt}]
        result = self.query_deepseek(messages)
        return result if result else "لا توجد نصائح متاحة حالياً."

    def generate_suggested_reply(self, text, sentiment, shop_type, customer_name="العميل"):
        tone = "اعتذاري ومهني" if sentiment == "سلبي" else "شكر وتقدير"
        prompt = f"""
        اكتب ردًا قصيرًا واحترافيًا لعميل متجر "{shop_type}".

        حالة التقييم: {sentiment}
        نص التقييم: "{text}"
        النبرة المطلوبة: {tone}

        الرد يجب أن يكون جاهزًا للنسخ والإرسال (بدون مقدمات).
        """
        messages = [{"role": "user", "content": prompt}]
        result = self.query_deepseek(messages)
        return result if result else "شكراً لك على تقييمك."

    def determine_overall_sentiment(self, stars, text, improve_product, additional_feedback):
        # دمج النصوص كلها
        text_combined = f"{text} {improve_product} {additional_feedback}".strip()

        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        url = "https://router.huggingface.co/models/CAMeL-Lab/bert-base-arabic-camelbert-da-sentiment"

        try:
            response = requests.post(url, headers=headers, json={"inputs": text_combined})
            if response.status_code == 200:
                result = response.json()
                if isinstance(result, list) and result:
                    label = result[0].get("label", "").lower()

                    # تحويل النتيجة إلى قيم عربية موحدة
                    if label in ["positive", "إيجابي", "label_1"]:
                        return "إيجابي"
                    elif label in ["negative", "سلبي", "label_0"]:
                        return "سلبي"
                    else:
                        return "محايد"
            else:
                logging.error(f"HuggingFace API error: {response.status_code} - {response.text}")
        except Exception as e:
            logging.error(f"Sentiment analysis error: {e}")

        # fallback إذا فشل الموديل أو رجع نتيجة غير واضحة
        if stars <= 2:
            return "سلبي"
        elif stars >= 4:
            return "إيجابي"
        return "محايد"
