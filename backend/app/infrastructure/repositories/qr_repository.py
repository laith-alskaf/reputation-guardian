"""QR Code repository."""
from typing import Optional
from bson import ObjectId
from app.domain.models.qr_code import QRCode
from app.infrastructure.repositories.base_repository import BaseRepository
from app.infrastructure.database import MongoDBManager
import logging

logger = logging.getLogger(__name__)


class QRRepository(BaseRepository[QRCode]):
    """Repository for QRCode entities."""
    
    def __init__(self):
        db = MongoDBManager().db
        super().__init__(db['qr_codes'])
    
    def to_entity(self, data: dict) -> QRCode:
        """Convert database document to QRCode entity."""
        return QRCode.from_dict(data)
    
    def to_document(self, entity: QRCode) -> dict:
        """Convert QRCode entity to database document."""
        return entity.to_dict()
    
    # Custom methods
    
    def find_by_user_id(self, user_id: ObjectId) -> Optional[QRCode]:
        """Find QR code by user ID."""
        return self.find_one({'user_id': user_id})
    
    def find_by_unique_id(self, unique_id: str) -> Optional[QRCode]:
        """Find QR code by unique ID."""
        return self.find_one({'unique_id': unique_id})
    
    def increment_scan_count(self, qr_id: ObjectId) -> bool:
        """Increment scan count for QR code."""
        result = self.collection.update_one(
            {'_id': qr_id},
            {'$inc': {'scan_count': 1}}
        )
        return result.modified_count > 0
