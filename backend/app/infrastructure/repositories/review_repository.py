"""Review repository."""
from typing import Optional, List
from bson import ObjectId
from app.domain.models.review import Review
from app.infrastructure.repositories.base_repository import BaseRepository
from app.infrastructure.database import MongoDBManager
import logging

logger = logging.getLogger(__name__)


class ReviewRepository(BaseRepository[Review]):
    """Repository for Review entities."""
    
    def __init__(self):
        db = MongoDBManager().db
        super().__init__(db['reviews'])
    
    def to_entity(self, data: dict) -> Review:
        """Convert database document to Review entity."""
        return Review.from_dict(data)
    
    def to_document(self, entity: Review) -> dict:
        """Convert Review entity to database document."""
        return entity.to_dict()
    
    # Custom methods
    
    def find_by_shop(self, shop_id: str) -> List[Review]:
        """Find all reviews for a shop."""
        return self.find_all({'shop_id': shop_id})
    
    def find_by_status(self, shop_id: str, status: str) -> List[Review]:
        """Find reviews for a shop with specific status."""
        return self.find_all({'shop_id': shop_id, 'status': status})
    
    def find_processed_by_shop(self, shop_id: str) -> List[Review]:
        """Find all PROCESSED reviews for a shop."""
        return self.find_by_status(shop_id, "processed")
    
    def find_rejected_by_shop(self, shop_id: str) -> List[Review]:
        """Find all REJECTED reviews for a shop."""
        return self.find_by_status(shop_id, "rejected")
    
    def find_existing_review(self, email: str, shop_id: str) -> Optional[Review]:
        """Find existing review by email and shop."""
        return self.find_one({'email': email, 'shop_id': shop_id})
    
    def create_review(self, review_data: dict) -> str:
        """
        Create a new review.
        
        Args:
            review_data: Dictionary with review data (can be from webhook or legacy format)
            
        Returns:
            Review ID as string
        """
        # If review_data contains an 'id' field (from webhook), remove it and use _id instead
        if 'id' in review_data and '_id' not in review_data:
            review_data['_id'] = ObjectId(review_data.pop('id'))
        
        # Insert the document directly to preserve nested structure from webhook
        result = self.collection.insert_one(review_data)
        logger.info(f"Created review for shop {review_data.get('shop_id', 'unknown')}")
        return str(result.inserted_id)
    
    def get_recent_reviews(self, shop_id: str, limit: int = 10) -> List[Review]:
        """Get recent reviews for a shop."""
        return self.find_all(
            filter_dict={'shop_id': shop_id},
            limit=limit,
            sort=[('timestamp', -1)]
        )
