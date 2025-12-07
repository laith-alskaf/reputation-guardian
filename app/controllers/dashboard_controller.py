from flask import Blueprint, request
from app.models.user import UserModel
from app.models.review import ReviewModel
from app.utils.middleware import token_required, handle_mongodb_errors
from app.utils.response import ResponseBuilder
from bson import ObjectId
import datetime
from datetime import timezone
import logging

dashboard_bp = Blueprint('dashboard', __name__)
user_model = UserModel()
review_model = ReviewModel()

def convert_object_ids(obj):
    if isinstance(obj, ObjectId):
        return str(obj)
    elif isinstance(obj, dict):
        return {key: convert_object_ids(value) for key, value in obj.items()}
    elif isinstance(obj, list):
        return [convert_object_ids(item) for item in obj]
    elif isinstance(obj, datetime.datetime):
        return obj.isoformat()
    else:
        return obj

@dashboard_bp.route('/dashboard', methods=['GET'])
@token_required
def get_dashboard():
    try:
        shop_id = request.shop_id

        try:
            ObjectId(shop_id)
        except:
            return ResponseBuilder.error("معرف المتجر غير صحيح", 400)

        user = user_model.find_by_id(shop_id)
        if not user:
            return ResponseBuilder.error("المتجر غير موجود", 404)

        reviews_list = review_model.find_by_shop(shop_id)

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
                "shop_name": user.get('shop_name', request.email),
                "shop_type": user.get('shop_type', request.shop_type),
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
            "last_updated": datetime.datetime.now(timezone.utc).isoformat()
        }

        dashboard_data = convert_object_ids(dashboard_data)

        return ResponseBuilder.success(dashboard_data, "تم جلب بيانات لوحة التحكم", 200)

    except Exception as e:
        error_message = handle_mongodb_errors(e)
        logging.error(f"Dashboard retrieval failed: {e}")
        return ResponseBuilder.error(error_message, 400)