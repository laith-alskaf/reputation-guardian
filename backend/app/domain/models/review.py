"""Review domain entity."""
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, Dict, Any
from bson import ObjectId


@dataclass
class Review:
    """Review domain entity with support for nested database schema."""
    
    shop_id: str
    email: Optional[str]
    status: str  # "processing", "processed", "rejected_low_quality", "rejected_irrelevant"
    
    # Nested objects from new schema
    source: Optional[Dict[str, Any]] = None  # Contains rating, fields
    processing: Optional[Dict[str, Any]] = None  # Contains concatenated_text, is_profane
    analysis: Optional[Dict[str, Any]] = None  # Contains sentiment, toxicity, category, quality, context, key_themes
    generated_content: Optional[Dict[str, Any]] = None  # Contains summary, actionable_insights, suggested_reply
    
    # Legacy flat fields for backward compatibility
    text: Optional[str] = None
    stars: Optional[int] = None
    overall_sentiment: Optional[str] = None
    sentiment_scores: Optional[Dict[str, float]] = None
    analysis_result: Optional[Dict[str, Any]] = None
    rejection_reason: Optional[str] = None
    
    # Metadata
    created_at: Optional[datetime] = None
    timestamp: Optional[datetime] = None
    id: Optional[ObjectId] = None
    
    @property
    def rating(self) -> int:
        """Get the review rating from source or legacy stars field."""
        if self.source and 'rating' in self.source:
            return self.source.get('rating', 0)
        return self.stars or 0
    
    @property
    def review_text(self) -> str:
        """Get the review text from processing or legacy text field."""
        if self.processing and 'concatenated_text' in self.processing:
            return self.processing.get('concatenated_text', '')
        return self.text or ''
    
    @property
    def sentiment(self) -> Optional[str]:
        """Get sentiment from analysis or legacy overall_sentiment field."""
        if self.analysis and 'sentiment' in self.analysis:
            return self.analysis.get('sentiment')
        return self.overall_sentiment
    
    def to_dict(self) -> dict:
        """Convert to dictionary for MongoDB, preserving the nested structure."""
        result = {
            '_id': self.id,
            'shop_id': self.shop_id,
            'email': self.email,
            'status': self.status,
        }
        
        # Add nested objects if present (new schema)
        if self.source is not None:
            result['source'] = self.source
        if self.processing is not None:
            result['processing'] = self.processing
        if self.analysis is not None:
            result['analysis'] = self.analysis
        if self.generated_content is not None:
            result['generated_content'] = self.generated_content
            
        # Add legacy fields if present
        if self.text is not None:
            result['text'] = self.text
        if self.stars is not None:
            result['stars'] = self.stars
        if self.overall_sentiment is not None:
            result['overall_sentiment'] = self.overall_sentiment
        if self.sentiment_scores is not None:
            result['sentiment_scores'] = self.sentiment_scores
        if self.analysis_result is not None:
            result['analysis_result'] = self.analysis_result
        if self.rejection_reason is not None:
            result['rejection_reason'] = self.rejection_reason
            
        # Add timestamps
        if self.created_at is not None:
            result['created_at'] = self.created_at
        if self.timestamp is not None:
            result['timestamp'] = self.timestamp
            
        return result
    
    @classmethod
    def from_dict(cls, data: dict) -> 'Review':
        """Create Review from MongoDB document, handling both new and legacy schemas."""
        return cls(
            id=data.get('_id'),
            shop_id=data.get('shop_id', ''),
            email=data.get('email'),
            status=data.get('status', 'processing'),
            
            # New nested schema fields
            source=data.get('source'),
            processing=data.get('processing'),
            analysis=data.get('analysis'),
            generated_content=data.get('generated_content'),
            
            # Legacy flat fields
            text=data.get('text'),
            stars=data.get('stars'),
            overall_sentiment=data.get('overall_sentiment'),
            sentiment_scores=data.get('sentiment_scores'),
            analysis_result=data.get('analysis_result'),
            rejection_reason=data.get('rejection_reason'),
            
            # Timestamps
            created_at=data.get('created_at'),
            timestamp=data.get('timestamp', datetime.utcnow())
        )
