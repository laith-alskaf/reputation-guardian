from app.services_interfaces import IDashboardService
from app.models.user import UserModel
from app.models.review import ReviewModel
from bson import ObjectId
import datetime
from datetime import timezone
from app.utils.time_utils import get_syria_time

class DashboardService(IDashboardService):
    def __init__(self):
        self.user_model = UserModel()
        self.review_model = ReviewModel()

    def convert_object_ids(self, obj):
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
        ObjectId(shop_id) # Validate shop_id format
        user = self.user_model.find_by_id(shop_id)
        if not user:
            return None

        # 1. Fetch reviews categorized by status
        processed_reviews = self.review_model.find_by_status(shop_id, "processed")
        rejected_quality_reviews = self.review_model.find_by_status(shop_id, "rejected_low_quality")
        rejected_irrelevant_reviews = self.review_model.find_by_status(shop_id, "rejected_irrelevant")

        # 2. Sort reviews by creation date
        processed_reviews.sort(key=lambda x: x.get('created_at', datetime.datetime.min), reverse=True)
        rejected_quality_reviews.sort(key=lambda x: x.get('created_at', datetime.datetime.min), reverse=True)
        rejected_irrelevant_reviews.sort(key=lambda x: x.get('created_at', datetime.datetime.min), reverse=True)

        # 3. Calculate metrics ONLY from processed reviews
        total_reviews = len(processed_reviews)
        if total_reviews > 0:
            avg_stars = sum(r.get('source', {}).get('rating', 0) for r in processed_reviews) / total_reviews
            
            sentiments = [r.get('analysis', {}).get('sentiment') for r in processed_reviews]
            negative_reviews = sentiments.count('سلبي')
            positive_reviews = sentiments.count('إيجابي')
            neutral_reviews = total_reviews - negative_reviews - positive_reviews
        else:
            avg_stars = 0
            negative_reviews = 0
            positive_reviews = 0
            neutral_reviews = 0

        # 4. Assemble the final data structure for the frontend
        internal_data = {
            "shop_info": {
                "shop_id": shop_id,
                "shop_name": user.get('shop_name', email),
                "shop_type": user.get('shop_type', shop_type),
                "created_at": user.get('created_at')
            },
            "metrics": {
                "total_reviews": total_reviews,
                "average_stars": round(avg_stars, 1),
                "negative_reviews": negative_reviews,
                "positive_reviews": positive_reviews,
                "neutral_reviews": neutral_reviews
            },
            "processed_reviews": processed_reviews[:50], # Limit to recent 50
            "rejected_quality_reviews": rejected_quality_reviews[:50],
            "rejected_irrelevant_reviews": rejected_irrelevant_reviews[:50],
            "qr_code": user.get('qr_code'),
            "last_updated": get_syria_time().isoformat()
        }

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

