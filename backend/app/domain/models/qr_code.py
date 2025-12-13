"""QR Code domain entity."""
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional
from bson import ObjectId


@dataclass
class QRCode:
    """QR Code domain entity."""
    
    user_id: ObjectId
    unique_id: str
    url: str
    created_at: datetime = field(default_factory=datetime.utcnow)
    id: Optional[ObjectId] = None
    is_active: bool = True
    scan_count: int = 0
    
    def to_dict(self) -> dict:
        """Convert to dictionary for MongoDB."""
        return {
            '_id': self.id,
            'user_id': self.user_id,
            'unique_id': self.unique_id,
            'url': self.url,
            'is_active': self.is_active,
            'scan_count': self.scan_count,
            'created_at': self.created_at
        }
    
    @classmethod
    def from_dict(cls, data: dict) -> 'QRCode':
        """Create QRCode from MongoDB document."""
        return cls(
            id=data.get('_id'),
            user_id=data['user_id'],
            unique_id=data['unique_id'],
            url=data['url'],
            is_active=data.get('is_active', True),
            scan_count=data.get('scan_count', 0),
            created_at=data.get('created_at', datetime.utcnow())
        )
