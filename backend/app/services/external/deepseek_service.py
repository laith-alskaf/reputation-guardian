import requests
import logging
import json
import re
from app.config import HF_TOKEN, MODEL_ID, API_URL
from app.dto.analysis_result_dto import AnalysisResultDTO
from app.services_interfaces import IDeepSeekService

class DeepSeekService(IDeepSeekService):
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

    def analyze_review_holistically(self,  stars, shop_type, enjoy_most=None, improve_product=None, additional_feedback=None) -> AnalysisResultDTO:
        """
        Performs a comprehensive analysis of the review using a single LLM call.
        Returns structured data including sentiment, category, insights, and reply.
        """
        
        # Combine all text inputs for context
        full_text = f"Main Review: \n"
        if enjoy_most: full_text += f"Pros: {enjoy_most}\n"
        if improve_product: full_text += f"Cons/Improvement: {improve_product}\n"
        if additional_feedback: full_text += f"Extra: {additional_feedback}\n"

        prompt = f"""
        You are an expert customer experience analyst for a business of type: "{shop_type}".
        Analyze the following customer review and provide the output in strict JSON format.

        Review Data:
        - Stars: {stars}/5
        - Content:
        {full_text}

        Task:
        1. Determine **Sentiment**: (positive, neutral, negative).
        2. Determine **Category**: (complaint, suggestion, praise, inquiry, or ambiguous).
        3. Extract **Key Themes**: List of 2-4 main topics (e.g., "Price", "Service", "Quality").
        4. Write a **Summary**: One short sentence summarizing the review.
        5. Provide **Actionable Insights**: List 2-3 concrete steps the business owner can take to improve (based on this review).
        6. Draft a **Suggested Reply**: A professional, empathetic, and culturally appropriate response in Arabic.
        7. Evaluate **Quality Score**: 0.0 to 1.0 (is it gibberish or spam? 1.0 is high quality).
        8. **Is Spam**: Boolean.
        9. **Context Match**: Boolean (Is this review relevant to a {shop_type}?).

        Output JSON structure:
        {{
            "sentiment": "...",
            "category": "...",
            "summary": "...",
            "key_themes": ["..."],
            "actionable_insights": ["..."],
            "suggested_reply": "...",
            "quality_score": 0.9,
            "is_spam": false,
            "context_match": true
        }}
        
        Ensure "summary", "key_themes", "actionable_insights", and "suggested_reply" are in ARABIC.
        Keep "sentiment" and "category" as English keys for internal logic.
        """

        messages = [
            {"role": "system", "content": "You are a helpful AI assistant that outputs strictly valid JSON."},
            {"role": "user", "content": prompt}
        ]

        raw_response = self.query_deepseek(messages, max_tokens=1500, temperature=0.5)
        
        if not raw_response:
            # Fallback if AI fails
            logging.error("DeepSeek returned None, using fallback.")
            return self._get_fallback_analysis(stars)

        try:
            # Clean up potential markdown code blocks ```json ... ```
            cleaned_json = raw_response.replace("```json", "").replace("```", "").strip()
            data = json.loads(cleaned_json)
            
            # Map English keys to Arabic for DB/Display compatibility
            data['sentiment'] = self._map_sentiment(data.get('sentiment'))
            data['category'] = self._map_category(data.get('category'))
            
            return AnalysisResultDTO.from_dict(data)
        except json.JSONDecodeError as e:
            logging.error(f"Failed to parse JSON from DeepSeek: {e}. Raw: {raw_response}")
            return self._get_fallback_analysis(stars)

    def _map_sentiment(self, sentiment_en):
        mapping = {
            "positive": "إيجابي",
            "neutral": "محايد",
            "negative": "سلبي"
        }
        return mapping.get(str(sentiment_en).lower(), "محايد")

    def _map_category(self, category_en):
        mapping = {
            "complaint": "شكوى",
            "suggestion": "اقتراح",
            "praise": "مدح",
            "inquiry": "استفسار",
            "ambiguous": "عام"
        }
        return mapping.get(str(category_en).lower(), "عام")

    def _get_fallback_analysis(self, stars):
        """Returns a safe default DTO if analysis fails."""
        sentiment = "إيجابي" if stars >= 4 else "سلبي" if stars <= 2 else "محايد"
        return AnalysisResultDTO(
            sentiment=sentiment,
            category="عام",
            summary="تم استلام التقييم.",
            key_themes=[],
            actionable_insights=["يرجى مراجعة التقييم يدوياً."],
            suggested_reply="شكراً لك على تقييمك.",
            quality_score=1.0,
            is_spam=False,
            context_match=True
        )

    # ------------------------------------------------------------------
    # Legacy methods kept for backward compatibility
    # ------------------------------------------------------------------

    def organize_customer_feedback(self, enjoy_most, improve_product, additional_feedback, shop_type="متجر عام"):
        return "Merged into holistic analysis."

    def generate_actionable_insights(self, text, improve_product, shop_type, stars=None):
        return ""

    def generate_suggested_reply(self, text, sentiment, shop_type, customer_name="العميل"):
        return ""

    def determine_overall_sentiment(self, stars, text, improve_product, additional_feedback):
        return "محايد"
