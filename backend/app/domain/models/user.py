"""User domain entity."""
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional
from bson import ObjectId


@dataclass
class User:
    """User domain entity."""
    
    email: str
    password_hash: str
    shop_name: str
    shop_type: str
    device_token: str = ""
    telegram_chat_id: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    id: Optional[ObjectId] = None
    is_active: bool = True
    
    def to_dict(self) -> dict:
        """Convert to dictionary for MongoDB."""
        return {
            '_id': self.id,
            'email': self.email,
            'password_hash': self.password_hash,
            'shop_name': self.shop_name,
            'shop_type': self.shop_type,
            'device_token': self.device_token,
            'telegram_chat_id': self.telegram_chat_id,
            'is_active': self.is_active,
            'created_at': self.created_at,
            'updated_at': self.updated_at
        }
    
    @classmethod
    def from_dict(cls, data: dict) -> 'User':
        """Create User from MongoDB document."""
        return cls(
            id=data.get('_id'),
            email=data['email'],
            password_hash=data.get('password_hash', ''),  # Fixed: make optional
            shop_name=data['shop_name'],
            shop_type=data['shop_type'],
            device_token=data.get('device_token', ''),
            telegram_chat_id=data.get('telegram_chat_id'),
            is_active=data.get('is_active', True),
            created_at=data.get('created_at', datetime.utcnow()),
            updated_at=data.get('updated_at', datetime.utcnow())
        )
