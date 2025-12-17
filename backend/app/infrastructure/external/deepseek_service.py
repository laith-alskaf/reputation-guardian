import requests
import logging
import json
from app.presentation.config import HF_TOKEN, MODEL_ID, API_URL
from app.application.dto.analysis_result_dto import AnalysisResultDTO
from app.application.dto.sentiment_analysis_result_dto import SentimentAnalysisResultDTO
from app.application.dto.review_dto import ReviewDTO

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
        
        full_text = f"التقييم الرئيسي: {getattr(dto, 'full_text', '')}\n"
        if dto.enjoy_most: full_text += f"الايجابيات: {dto.enjoy_most}\n"
        if dto.improve_product: full_text += f"نقاط التحسين: {dto.improve_product}\n"
        if dto.additional_feedback: full_text += f"ملاحظات إضافية: {dto.additional_feedback}\n"

        prompt = f"""
        Role: Senior CS Manager for "{shop_type}".
        Input: "{full_text}"
        Stats: {dto.stars}/5 stars | Sentiment: {sentiment_result.sentiment} | Toxic: {sentiment_result.toxicity}
        
        Task: Analyze & output JSON in Arabic.

        1. Category (Select one):
        - "شكوى": Operational failure (rude staff, hygiene, delay, wrong order).
        - "نقد": Subjective opinion, price/quality, constructive criticism.
        - "مدح": Positive feedback.
        - "اقتراح": Suggestion/Idea.
        - "استفسار": Question.

        2. Content:
        - summary: Concise (<15 words).
        - key_themes: 2-4 main topics.
        - actionable_insights: 2-3 practical steps (no generic advice).
        - suggested_reply: Professional, empathetic, human-like (Apologize for complaints, Thank for praise/critique).
        
        Output JSON:
        {{
            "category": "...",
            "summary": "...",
            "key_themes": ["..."],
            "actionable_insights": ["..."],
            "suggested_reply": "..."
        }}
        """

        messages = [
            {"role": "system", "content": "You are a helpful AI assistant. Output strictly valid JSON. Language: Arabic."},
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
                category=data.get('category', 'عام'),
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
        # Fallback classification logic
        fallback_category = "عام"
        if sentiment_result.sentiment == "سلبي" or (stars and stars <= 2):
            fallback_category = "شكوى"
        elif sentiment_result.sentiment == "إيجابي" or (stars and stars >= 4):
            fallback_category = "إيجابي"
        else:
            fallback_category = "نقد"

        return AnalysisResultDTO(
            sentiment=sentiment_result.sentiment,
            category=fallback_category,
            summary="تم استلام التقييم وسيتم مراجعته.",
            key_themes=["خدمة عام", "تجربة العميل"],
            actionable_insights=["سنقوم بمراجعة التقييم بعناية", "سنعمل على تحسين الخدمة"],
            suggested_reply="شكراً جزيلاً لك على تقييمك القيم. نحن نقدر ملاحظاتك وسنعمل على تحسين خدماتنا بناءً عليها.",
            quality_score=sentiment_result.quality_score,
            is_spam=sentiment_result.is_spam,
            context_match=sentiment_result.context_match
        )
