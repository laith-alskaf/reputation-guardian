import requests
import logging
from app.config import HF_TOKEN, HF_SENTIMENT_MODEL_URL
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

    def organize_customer_feedback(self, enjoy_most, improve_product, additional_feedback, shop_type="متجر عام"):
        enjoy_clean = SentimentService.clean_text(enjoy_most)
        improve_clean = SentimentService.clean_text(improve_product)
        additional_clean = SentimentService.clean_text(additional_feedback)

        prompt = f"""
        أنت محلل آراء عملاء متخصص في مجال {shop_type}. قم بتلخيص وتنظيم الملاحظات التالية في نقاط واضحة باللغة العربية مع مراعاة طبيعة النشاط التجاري:

        **ما أعجب العميل:** {enjoy_clean if enjoy_clean else "لم يذكر نقاط إيجابية محددة"}
        **اقتراحات التحسين:** {improve_clean if improve_clean else "لم يقدم اقتراحات محددة"}
        **ملاحظات إضافية:** {additional_clean if additional_clean else "لا توجد ملاحظات إضافية"}

        **تعليمات مهمة:**
        - ركز على الجوانب المتعلقة بنشاط {shop_type}
        - استخدم صيغة مهنية ومنظمة
        - إذا كانت الملاحظات لا تتناسب مع نوع المتجر، أشر لذلك
        - كن موجزاً ولكن شاملاً

        الإجابة بتنسيق واضح ومنظم.
        """
        messages = [{"role": "user", "content": prompt}]
        result = self.query_deepseek(messages)
        return result if result else "تعذر تنظيم الملاحظات."

    def generate_actionable_insights(self, text, improve_product, shop_type, stars=None):
        # تحليل إضافي للسياق
        context_analysis = ""
        if stars is not None:
            if stars <= 2:
                context_analysis = "العميل منح نجوم قليلة جداً، مما يشير لمشكلة خطيرة تحتاج حل فوري."
            elif stars == 3:
                context_analysis = "العميل منح تقييماً متوسطاً، يمكن تحويله لإيجابي بتحسينات بسيطة."

        prompt = f"""
        بصفتك مستشار أعمال خبير ومحلل آراء عملاء متخصص في مجال {shop_type}، قدم 3 نصائح عملية وقابلة للتنفيذ بناءً على الشكوى التالية:

        **الشكوى الأساسية:** "{text}"
        **اقتراحات العميل للتحسين:** "{improve_product or 'لم يقدم اقتراحات محددة'}"
        **نوع النشاط:** {shop_type}
        **تحليل السياق:** {context_analysis}

        **متطلبات النصائح:**
        1. **عملية وقابلة للتنفيذ فوراً** - خطوات يمكن تطبيقها خلال أيام قليلة
        2. **مرتبطة بنشاط {shop_type}** - تركز على الجوانب المتعلقة بنوع المتجر
        3. **مرتبة حسب الأولوية** - الأكثر تأثيراً أولاً
        4. **تشمل جدولة زمنية** - متى يجب تطبيق كل خطوة

        **التنسيق المطلوب:**
        ### 1. [عنوان واضح للخطوة]
        - **الإجراء:** [وصف الخطوة بالتفصيل]
        - **الهدف:** [ما سيحققه هذا الإجراء]
        - **التنفيذ السريع:** [كيفية التطبيق في أقل من أسبوع]

        (كرر للخطوات 2 و 3)
        """
        messages = [{"role": "user", "content": prompt}]
        result = self.query_deepseek(messages, max_tokens=800)  # زيادة max_tokens للنصائح الأطول
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
        url = HF_SENTIMENT_MODEL_URL

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
