"""
Relevancy Gate Processor
Checks context relevancy for reviews to ensure they match the shop type.
"""
import logging
from typing import Tuple, Dict
from bson import ObjectId

from app.infrastructure.external import SentimentService
from app.application.dto.review_processing_dto import ReviewDocument, Source, Processing


class RelevancyGateProcessor:
    """
    Processes review relevancy assessment.
    
    Responsibility: Determine if review content is relevant to shop category.
    Follows SRP - only handles relevancy gate logic.
    """
    
    def __init__(self, sentiment_service: SentimentService):
        """
        Initialize RelevancyGateProcessor with required dependencies.
        
        Args:
            sentiment_service: Service for sentiment and context analysis
        """
        self.sentiment_service = sentiment_service
    
    def check_relevancy(
        self,
        text: str,
        shop_type: str,
        quality_flags: list
    ) -> Tuple[bool, dict]:
        """
        Check if review content is relevant to the shop type.
        
        Args:
            text: Review text content
            shop_type: Category/type of the shop
            quality_flags: Flags from quality assessment
            
        Returns:
            Tuple of (is_relevant, context_check_result)
            - is_relevant: Boolean indicating if review is relevant
            - context_check_result: Full context check results
        """
        # Check if context check should be skipped
        if self.should_skip_context_check(text, quality_flags):
            skip_reason = 'stars-only' if 'stars_only' in quality_flags else 'insufficient text'
            logging.info(f"⚡ Skipping context check - {skip_reason}")
            
            return True, {
                'mismatch_score': 0.0,
                'confidence': 100.0,
                'reasons': [],
                'has_mismatch': False,
                'predicted_label': f'N/A ({skip_reason})'
            }
        
        # Perform context mismatch detection
        context_check_result = self.sentiment_service.detect_context_mismatch(text, shop_type)
        
        has_mismatch = context_check_result.get('has_mismatch', False)
        
        if has_mismatch:
            logging.warning(f"Context mismatch detected. Reason: {context_check_result.get('reasons')}")
        
        return not has_mismatch, context_check_result
    
    def should_skip_context_check(self, text: str, quality_flags: list) -> bool:
        """
        Determine if context check should be skipped.
        
        Context check is skipped for:
        - Stars-only reviews (no meaningful text)
        - Reviews with insufficient text (<10 characters)
        
        Args:
            text: Review text content
            quality_flags: Flags from quality assessment
            
        Returns:
            True if context check should be skipped, False otherwise
        """
        is_stars_only = 'stars_only' in quality_flags
        has_insufficient_text = not text or len(text.strip()) < 10
        
        return is_stars_only or has_insufficient_text
    
    def create_rejected_relevancy_document(
        self,
        shop_id: str,
        email: str,
        rating: int,
        source: Source,
        processing: Processing,
        quality_result: dict,
        context_result: dict
    ) -> ReviewDocument:
        """
        Create a ReviewDocument for a review rejected due to irrelevance.
        
        Args:
            shop_id: Shop identifier
            email: Respondent email
            rating: Star rating
            source: Source data object
            processing: Processing data object
            quality_result: Quality assessment results
            context_result: Context check results
            
        Returns:
            ReviewDocument with status 'rejected_irrelevant'
        """
        return ReviewDocument(
            id=str(ObjectId()),
            shop_id=shop_id,
            email=email,
            stars=rating,
            status="rejected_irrelevant",
            overall_sentiment="محايد",
            source=source,
            processing=processing,
            analysis={
                'quality': quality_result,
                'context': context_result
            }
        )
