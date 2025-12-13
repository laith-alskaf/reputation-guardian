from dataclasses import dataclass, field
from typing import List, Optional

@dataclass
class AnalysisResultDTO:
    sentiment: str  # positive, neutral, negative
    category: str   # complaint, suggestion, praise, inquiry
    summary: str
    key_themes: List[str]
    actionable_insights: List[str]
    suggested_reply: str
    quality_score: float
    is_spam: bool
    context_match: bool
    
    @classmethod
    def from_dict(cls, data: dict):
        return cls(
            sentiment=data.get('sentiment', 'neutral'),
            category=data.get('category', 'inquiry'),
            summary=data.get('summary', ''),
            key_themes=data.get('key_themes', []),
            actionable_insights=data.get('actionable_insights', []),
            suggested_reply=data.get('suggested_reply', ''),
            quality_score=data.get('quality_score', 1.0),
            is_spam=data.get('is_spam', False),
            context_match=data.get('context_match', True)
        )
