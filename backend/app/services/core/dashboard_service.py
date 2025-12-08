from app.services_interfaces import IDashboardService
from app.models.user import UserModel
from app.models.review import ReviewModel
from bson import ObjectId
import datetime
from datetime import timezone

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
        # تحقق من صحة ObjectId
        ObjectId(shop_id)

        user = self.user_model.find_by_id(shop_id)
        if not user:
            return None

        reviews_list = self.review_model.find_by_shop(shop_id)

        total_reviews = len(reviews_list)
        if total_reviews > 0:
            avg_stars = sum(review.get('stars', 0) for review in reviews_list) / total_reviews
            negative_reviews = len([r for r in reviews_list if r.get('overall_sentiment') == 'سلبي'])
            positive_reviews = len([r for r in reviews_list if r.get('overall_sentiment') == 'إيجابي'])
        else:
            avg_stars = 0
            negative_reviews = 0
            positive_reviews = 0

        recent_reviews = reviews_list[-10:] if reviews_list else []

        dashboard_data = {
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
                "neutral_reviews": total_reviews - negative_reviews - positive_reviews
            },
            "recent_reviews": recent_reviews,
            "qr_code": user.get('qr_code'),
            "last_updated": datetime.datetime.now(timezone.utc).isoformat()
        }

        return self.convert_object_ids(dashboard_data)
