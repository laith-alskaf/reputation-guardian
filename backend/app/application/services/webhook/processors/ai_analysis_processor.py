"""
AI Analysis Processor
Performs AI sentiment analysis and generates insights for reviews.
"""
import logging
from typing import Dict, Any

from app.infrastructure.external import SentimentService, DeepSeekService
from app.application.dto.sentiment_analysis_result_dto import SentimentAnalysisResultDTO
from app.application.dto.analysis_result_dto import AnalysisResultDTO


class AIAnalysisProcessor:
    """
    Processes AI analysis for reviews.
    
    Responsibility: Perform sentiment analysis and generate AI insights.
    Follows SRP - only handles AI analysis logic.
    """
    
    def __init__(self, sentiment_service: SentimentService, deepseek_service: DeepSeekService):
        """
        Initialize AIAnalysisProcessor with required dependencies.
        
        Args:
            sentiment_service: Service for sentiment analysis
            deepseek_service: Service for AI insights generation
        """
        self.sentiment_service = sentiment_service
        self.deepseek_service = deepseek_service
    
    def analyze(
        self,
        text: str,
        rating: int,
        source_fields: Dict[str, Any],
        shop_type: str,
        quality_result: dict
    ) -> Dict[str, Any]:
        """
        Perform full AI analysis on review text.
        
        Args:
            text: Concatenated review text
            rating: Star rating
            source_fields: Original form fields
            shop_type: Category/type of the shop
            quality_result: Quality assessment results
            
        Returns:
            Dictionary containing:
            - sentiment: Overall sentiment classification
            - toxicity: Toxicity status
            - category: Review category
            - key_themes: List of identified themes
            - generated_content: AI-generated summary, insights, and reply
        """
        # Check if AI processing should be skipped
        should_skip = self.should_skip_ai_processing(text, quality_result.get('flags', []))
        
        if should_skip:
            logging.info(f"⚡ Skipping AI processing - stars-only or no text content")
            return self._generate_simple_analysis(rating, quality_result.get('toxicity_status', 'non-toxic'))
        
        # Perform full AI analysis
        logging.info(f"🤖 Running full AI analysis")
        
        # A) Sentiment Analysis
        sentiment = self.sentiment_service.analyze_sentiment(text)
        toxicity = quality_result.get('toxicity_status', 'non-toxic')
        
        # B) DeepSeek AI Analysis for insights and replies
        temp_sentiment_dto = SentimentAnalysisResultDTO(
            sentiment=sentiment,
            toxicity=toxicity,
            category="pending",
            quality_score=quality_result.get('quality_score', 1.0),
            is_spam=False,
            context_match=True,
            quality_flags=[],
            mismatch_reasons=[]
        )
        
        # Create temporary review DTO for DeepSeek
        temp_review_dto = self._create_temp_review_dto(rating, text, source_fields)
        
        # Get AI insights
        deepseek_result: AnalysisResultDTO = self.deepseek_service.format_insights_and_reply(
            dto=temp_review_dto,
            sentiment_result=temp_sentiment_dto,
            shop_type=shop_type
        )
        
        return {
            "sentiment": sentiment,
            "toxicity": toxicity,
            "category": deepseek_result.category,
            "key_themes": deepseek_result.key_themes,
            "generated_content": {
                "summary": deepseek_result.summary,
                "actionable_insights": deepseek_result.actionable_insights,
                "suggested_reply": deepseek_result.suggested_reply,
            }
        }
    
    def should_skip_ai_processing(self, text: str, quality_flags: list) -> bool:
        """
        Determine if AI processing should be skipped.
        
        AI processing is skipped for:
        - Stars-only reviews
        - Reviews with insufficient text (<15 characters)
        
        Args:
            text: Review text content
            quality_flags: Flags from quality assessment
            
        Returns:
            True if AI processing should be skipped, False otherwise
        """
        is_stars_only = 'stars_only' in quality_flags
        has_insufficient_text = not text or len(text.strip()) < 15
        
        return is_stars_only or has_insufficient_text
    
    def _generate_simple_analysis(self, rating: int, toxicity: str) -> Dict[str, Any]:
        """
        Generate simple analysis for stars-only reviews without AI.
        
        Args:
            rating: Star rating
            toxicity: Toxicity status from quality check
            
        Returns:
            Dictionary with simple sentiment, category, and generated content
        """
        # Infer sentiment from rating
        if rating >= 4:
            sentiment = "إيجابي"
            category = "مدح"
        elif rating <= 2:
            sentiment = "سلبي"
            category = "شكوى"
        else:
            sentiment = "محايد"
            category = "محايد"
        
        # Simple generated content
        stars_display = '⭐' * rating
        generated_content = {
            "summary": f"تقييم {stars_display} بدون تعليقات نصية",
            "actionable_insights": [],
            "suggested_reply": "شكراً لتقييمك!"
        }
        
        return {
            "sentiment": sentiment,
            "toxicity": toxicity,
            "category": category,
            "key_themes": [],
            "generated_content": generated_content
        }
    
    def _create_temp_review_dto(self, rating: int, text: str, source_fields: Dict[str, Any]):
        """
        Create a temporary review DTO for DeepSeek service.
        
        Args:
            rating: Star rating
            text: Full review text
            source_fields: Original form fields
            
        Returns:
            Temporary review DTO object
        """
        class TempReviewDTO:
            def __init__(self, stars, full_text, fields):
                self.stars = stars
                self.full_text = full_text
                self._source_fields = fields
                
                self.enjoy_most = self._get_field_value("enjoy_most")
                self.improve_product = self._get_field_value("improve_product")
                self.additional_feedback = self._get_field_value("additional_feedback")
            
            def _get_field_value(self, label):
                return self._source_fields.get(label, "")
        
        return TempReviewDTO(rating, text, source_fields)
