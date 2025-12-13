"""Review status enumeration."""
from enum import Enum


class ReviewStatus(str, Enum):
    """Review status enumeration."""
    
    PROCESSING = "processing"
    PROCESSED = "processed"
    REJECTED = "rejected"
    
    @classmethod
    def values(cls):
        """Get all enum values."""
        return [item.value for item in cls]
    
    @classmethod
    def is_valid(cls, value: str) -> bool:
        """Check if value is valid."""
        return value in cls.values()
