from __future__ import annotations
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional, Literal
from datetime import datetime

class Source(BaseModel):
    rating: Optional[int] = None
    fields: Dict[str, Any]

class Processing(BaseModel):
    concatenated_text: str
    is_profane: bool

class ReviewDocument(BaseModel):
    id: str # Unique identifier for the review
    shop_id: str
    email: Optional[str] = None
    stars: Optional[int] = None
    overall_sentiment: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    status: Literal["pending", "processed", "rejected_low_quality", "rejected_irrelevant"]
    source: Source
    processing: Processing
    analysis: Optional[Dict[str, Any]] = None
    generated_content: Optional[Dict[str, Any]] = None

    class Config:
        populate_by_name = True
        json_encoders = {
            datetime: lambda dt: dt.isoformat(),
            # Potentially for ObjectId if using pymongo's native type
            # ObjectId: str 
        }
