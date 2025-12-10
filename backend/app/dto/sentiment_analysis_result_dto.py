from dataclasses import dataclass, field
from typing import List, Optional

@dataclass
class SentimentAnalysisResultDTO:
    sentiment: str
    toxicity: str
    category: str
    quality_score: float
    is_spam: bool
    context_match: bool
    quality_flags: List[str] = field(default_factory=list)
    mismatch_reasons: List[str] = field(default_factory=list)
    
    @classmethod
    def from_dict(cls, data: dict):
        return cls(
            sentiment=data.get('sentiment', 'محايد'),
            toxicity=data.get('toxicity', 'non-toxic'),
            category=data.get('category', 'عام'),
            quality_score=data.get('quality_score', 1.0),
            is_spam=data.get('is_spam', False),
            context_match=data.get('context_match', True),
            quality_flags=data.get('quality_flags', []),
            mismatch_reasons=data.get('mismatch_reasons', [])
        )
    
    def to_dict(self):
        return {
            'sentiment': self.sentiment,
            'toxicity': self.toxicity,
            'category': self.category,
            'quality_score': self.quality_score,
            'is_spam': self.is_spam,
            'context_match': self.context_match,
            'quality_flags': self.quality_flags,
            'mismatch_reasons': self.mismatch_reasons
        }
