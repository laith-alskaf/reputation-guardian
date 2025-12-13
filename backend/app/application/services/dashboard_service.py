from app.domain.services_interfaces import IDashboardService
from app.infrastructure.repositories import UserRepository, ReviewRepository
from bson import ObjectId
import datetime
from app.presentation.utils.time_utils import get_syria_time
import logging

logger = logging.getLogger(__name__)


class DashboardService(IDashboardService):
    def __init__(self, user_repository: UserRepository = None, review_repository: ReviewRepository = None):
        """
        Initialize DashboardService with dependency injection.
        
        Args:
            user_repository: User repository (injected for testing)
            review_repository: Review repository (injected for testing)
        """
        self.user_repository = user_repository or UserRepository()
        self.review_repository = review_repository or ReviewRepository()

    def convert_object_ids(self, obj):
        """Convert ObjectIds and datetimes to strings."""
        if isinstance(obj, ObjectId):
            return str(obj)
        elif isinstance(obj, dict):
            return {key: self.convert_object_ids(value) for key, value in obj.items()}
        elif isinstance(obj, list):
            return [self.convert_object_ids(item) for item in obj]
        elif isinstance(obj, datetime.datetime):
            return obj.isoformat()
        else:
            return obj

    def get_dashboard_data(self, shop_id: str, email: str, shop_type: str) -> dict:
        """Get dashboard data for a shop."""
        # Validate shop_id format
        user_oid = ObjectId(shop_id)
        
        # Find user
        user = self.user_repository.find_by_id(user_oid)
        if not user:
            logger.warning(f"User not found: {shop_id}")
            return None

        # 1. Fetch reviews categorized by status
        processed_reviews = self.review_repository.find_by_status(shop_id, "processed")
        rejected_quality_reviews = self.review_repository.find_by_status(shop_id, "rejected_low_quality")
        rejected_irrelevant_reviews = self.review_repository.find_by_status(shop_id, "rejected_irrelevant")

        # Convert to dicts for easier processing (temporary)
        processed_dicts = [r.to_dict() for r in processed_reviews]
        rejected_quality_dicts = [r.to_dict() for r in rejected_quality_reviews]
        rejected_irrelevant_dicts = [r.to_dict() for r in rejected_irrelevant_reviews]

        # 2. Sort reviews by creation date
        processed_dicts.sort(key=lambda x: x.get('created_at', datetime.datetime.min), reverse=True)
        rejected_quality_dicts.sort(key=lambda x: x.get('created_at', datetime.datetime.min), reverse=True)
        rejected_irrelevant_dicts.sort(key=lambda x: x.get('created_at', datetime.datetime.min), reverse=True)

        # 3. Calculate metrics ONLY from processed reviews
        total_reviews = len(processed_dicts)
        if total_reviews > 0:
            avg_stars = sum(r.get('source', {}).get('rating', 0) for r in processed_dicts) / total_reviews
            
            sentiments = [r.get('analysis', {}).get('sentiment') for r in processed_dicts]
            negative_reviews = sentiments.count('سلبي')
            positive_reviews = sentiments.count('إيجابي')
            neutral_reviews = total_reviews - negative_reviews - positive_reviews
        else:
            avg_stars = 0
            negative_reviews = 0
            positive_reviews = 0
            neutral_reviews = 0

        # 4. Assemble the final data structure
        internal_data = {
            "shop_info": {
                "shop_id": shop_id,
                "shop_name": user.shop_name or email,
                "shop_type": user.shop_type or shop_type,
                "created_at": user.created_at
            },
            "metrics": {
                "total_reviews": total_reviews,
                "average_stars": round(avg_stars, 1),
                "negative_reviews": negative_reviews,
                "positive_reviews": positive_reviews,
                "neutral_reviews": neutral_reviews
            },
            "processed_reviews": processed_dicts[:50],  # Limit to recent 50
            "rejected_quality_reviews": rejected_quality_dicts[:50],
            "rejected_irrelevant_reviews": rejected_irrelevant_dicts[:50],
            "qr_code": None,  # QR code logic can be added if needed
            "last_updated": get_syria_time().isoformat()
        }

        logger.info(f"Dashboard data retrieved for shop {shop_id}: {total_reviews} reviews")
        return self.convert_object_ids(internal_data)

    def get_rejected_reviews(self, shop_id: str) -> dict:
        """
        DEPRECATED: This method is no longer needed as rejected reviews are now
        fetched as part of the main get_dashboard_data call.
        """
        return self.convert_object_ids({
            "rejected_quality_reviews": [],
            "rejected_irrelevant_reviews": []
        })

