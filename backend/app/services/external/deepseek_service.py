import requests
import logging
import json
from app.config import HF_TOKEN, MODEL_ID, API_URL
from app.dto.analysis_result_dto import AnalysisResultDTO
from app.dto.sentiment_analysis_result_dto import SentimentAnalysisResultDTO
from app.dto.review_dto import ReviewDTO

class DeepSeekService:
    def __init__(self):
        self.headers = {"Authorization": f"Bearer {HF_TOKEN}"}

    def query_deepseek(self, messages, max_tokens=1000, temperature=0.7):
        payload = {
            "model": MODEL_ID,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "response_format": {"type": "json_object"} 
        }
        try:
            response = requests.post(API_URL, headers=self.headers, json=payload)
            response.raise_for_status()
            
            content = response.json()["choices"][0]["message"]["content"]
            return content
        except Exception as e:
            logging.error(f"AI Model Query Error: {e}")
            return None

    def format_insights_and_reply(
        self,
        dto: ReviewDTO,
        sentiment_result: SentimentAnalysisResultDTO,
        shop_type: str
    ) -> AnalysisResultDTO:
        """
        يستقبل نتائج التحليل من SentimentServiceV2 ويركز على:
        ✓ تنظيم وتنسيق النصوص الناتجة
        ✓ اقتراح حلول وتحسينات بناءً على النوع
        ✓ صياغة رد احترافي مناسب ثقافياً
        """
        
        full_text = f"التقييم الرئيسي: {''}\n"
        if dto.enjoy_most: full_text += f"الايجابيات: {dto.enjoy_most}\n"
        if dto.improve_product: full_text += f"نقاط التحسين: {dto.improve_product}\n"
        if dto.additional_feedback: full_text += f"ملاحظات إضافية: {dto.additional_feedback}\n"

        prompt = f"""
        أنت خبير في خدمة العملاء وتحليل التقييمات لنوع متجر: "{shop_type}".
        
        البيانات التحليلية الأولية (من النظام):
        - المشاعر الكلية: {sentiment_result.sentiment}
        - درجة السمية: {sentiment_result.toxicity}
        - نوع التقييم: {sentiment_result.category}
        - النجوم: {dto.stars}/5
        
        محتوى التقييم:
        {full_text}
        
        مهمتك:
        1. **تنظيم الملخص**: اكتب ملخص واحد قصير بالعربية يجمع أهم النقاط
        2. **المواضيع الرئيسية**: استخرج 2-4 مواضيع رئيسية من التقييم
        3. **الحلول الملموسة**: اقترح 2-3 خطوات عملية محددة لتحسين الخدمة/المنتج
           - ركز على ما يمكن للمتجر تنفيذه فعلاً
           - كن محدداً وعملياً (تجنب الإجابات العامة)
        4. **الرد المهني**: اكتب رد احترافي، تعاطفي، ومناسب ثقافياً بالعربية
           - اشكر العميل على التقييم
           - أظهر فهمك لآراءه
           - أذكر أن المتجر سيعمل على التحسين
           - تجنب الدفاع أو العتاب
        
        أرجع الإجابة بصيغة JSON صارمة:
        {{
            "summary": "ملخص قصير جداً",
            "key_themes": ["موضوع1", "موضوع2", "موضوع3"],
            "actionable_insights": ["حل عملي1", "حل عملي2", "حل عملي3"],
            "suggested_reply": "الرد الاحترافي الطويل نسبياً..."
        }}
        
        تأكد من أن جميع الحقول بالعربية.
        """

        messages = [
            {"role": "system", "content": "You are a helpful AI assistant that outputs strictly valid JSON and writes responses only in Arabic."},
            {"role": "user", "content": prompt}
        ]

        raw_response = self.query_deepseek(messages, max_tokens=1500, temperature=0.5)
        
        if not raw_response:
            logging.error("DeepSeek returned None, using fallback.")
            return self._get_fallback_analysis(sentiment_result, dto.stars)

        try:
            cleaned_json = raw_response.replace("```json", "").replace("```", "").strip()
            data = json.loads(cleaned_json)
            
            return AnalysisResultDTO(
                sentiment=sentiment_result.sentiment,
                category=sentiment_result.category,
                summary=data.get('summary', 'تم استلام التقييم'),
                key_themes=data.get('key_themes', []),
                actionable_insights=data.get('actionable_insights', []),
                suggested_reply=data.get('suggested_reply', 'شكراً لك على تقييمك'),
                quality_score=sentiment_result.quality_score,
                is_spam=sentiment_result.is_spam,
                context_match=sentiment_result.context_match
            )
        except json.JSONDecodeError as e:
            logging.error(f"Failed to parse JSON from DeepSeek: {e}. Raw: {raw_response}")
            return self._get_fallback_analysis(sentiment_result, dto.stars)

    def _get_fallback_analysis(self, sentiment_result: SentimentAnalysisResultDTO, stars: int):
        """يرجع إجابة آمنة في حالة فشل DeepSeek"""
        return AnalysisResultDTO(
            sentiment=sentiment_result.sentiment,
            category=sentiment_result.category,
            summary="تم استلام التقييم وسيتم مراجعته.",
            key_themes=["خدمة عام", "تجربة العميل"],
            actionable_insights=["سنقوم بمراجعة التقييم بعناية", "سنعمل على تحسين الخدمة"],
            suggested_reply="شكراً جزيلاً لك على تقييمك القيم. نحن نقدر ملاحظاتك وسنعمل على تحسين خدماتنا بناءً عليها.",
            quality_score=sentiment_result.quality_score,
            is_spam=sentiment_result.is_spam,
            context_match=sentiment_result.context_match
        )
