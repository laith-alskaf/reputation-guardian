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

        # استخدام دالة get_recent_reviews للحصول على التقييمات مرتبة
        # ولكن هنا نحتاج كل التقييمات لحساب المقاييس
        reviews_list = self.review_model.find_by_shop(shop_id)
        
        # فرز التقييمات حسب التاريخ تنازلياً للتأكد من أن القائمة مرتبة
        reviews_list.sort(key=lambda x: x.get('timestamp', datetime.datetime.min), reverse=True)

        total_reviews = len(reviews_list)
        if total_reviews > 0:
            avg_stars = sum(review.get('stars', 0) for review in reviews_list) / total_reviews
            negative_reviews = len([r for r in reviews_list if r.get('overall_sentiment') == 'سلبي'])
            positive_reviews = len([r for r in reviews_list if r.get('overall_sentiment') == 'إيجابي'])
            neutral_reviews = len([r for r in reviews_list if r.get('overall_sentiment') == 'محايد'])
            
            # إذا كان هناك تقييمات ليست إيجابية/سلبية/محايدة (مثل قيم قديمة أو null)، نعتبرها محايدة
            calculated_neutral = total_reviews - negative_reviews - positive_reviews
            if calculated_neutral != neutral_reviews:
                 # fallback logic just in case
                 neutral_reviews = calculated_neutral
        else:
            avg_stars = 0
            negative_reviews = 0
            positive_reviews = 0
            neutral_reviews = 0

        # أخذ أحدث 10 تقييمات
        recent_reviews = reviews_list[:10] if reviews_list else []

        dashboard_data = {
            "data": {
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
                "recent_reviews": recent_reviews,
                "qr_code": user.get('qr_code'),
                "last_updated": datetime.datetime.now(timezone.utc).isoformat()
            },
            "message": "تم جلب بيانات لوحة التحكم",
            "status": "success"
        }

        # ملاحظة: الكنترولر الحالي يقوم بتغليف الرد بـ ResponseBuilder.
        # لذا يجب أن نرجع فقط القاموس الداخلي "data" إذا كنا نريد الحفاظ على الاتساق مع الكنترولر،
        # أو تعديل الكنترولر.
        # الكود الحالي للكنترولر: return ResponseBuilder.success(dashboard_data, ...)
        # هذا سيضع dashboard_data داخل مفتاح "data" في JSON النهائي.
        # لذلك يجب أن نرجع الهيكل الداخلي فقط هنا.
        
        internal_data = {
            "shop_info": dashboard_data["data"]["shop_info"],
            "metrics": dashboard_data["data"]["metrics"],
            "recent_reviews": dashboard_data["data"]["recent_reviews"],
            "qr_code": dashboard_data["data"]["qr_code"],
            "last_updated": dashboard_data["data"]["last_updated"]
        }

        return self.convert_object_ids(internal_data)
