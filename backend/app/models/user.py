from bson import ObjectId
import datetime
from datetime import timezone
from app.utils.db import connect_to_mongodb
from app.utils.time_utils import get_syria_time
import bcrypt

class UserModel:
    def __init__(self):
        self.db = connect_to_mongodb()
        self.collection = self.db['users']

    def find_by_email(self, email):
        return self.collection.find_one({"email": email.lower().strip()})

    def find_by_id(self, user_id):
        try:
            return self.collection.find_one({"_id": ObjectId(user_id)})
        except:
            return None

    def create_user(self, email, password, shop_name, shop_type, device_token=''):
        hashed_pw = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        user_data = {
            "email": email.lower().strip(),
            "password": hashed_pw,
            "shop_name": shop_name.strip(),
            "shop_type": shop_type,
            "device_token": (device_token or "").strip(),
            "created_at": get_syria_time()
        }
        result = self.collection.insert_one(user_data)
        return str(result.inserted_id)

    def verify_password(self, stored_password, provided_password):
        return bcrypt.checkpw(provided_password.encode('utf-8'), stored_password)

    def update_qr_code(self, shop_id, qr_base64):
        return self.collection.update_one(
            {"_id": ObjectId(shop_id)},
            {"$set": {"qr_code": qr_base64, "qr_updated_at": get_syria_time()}}
        )

    def update_user(self, user_id, update_data):
        """تحديث بيانات المستخدم"""
        # تصفية الحقول المسموح بتحديثها فقط
        allowed_fields = ['shop_name', 'shop_type', 'device_token', 'telegram_chat_id']
        filtered_data = {k: v for k, v in update_data.items() if k in allowed_fields}
        
        if not filtered_data:
            return None
            
        filtered_data['updated_at'] = get_syria_time()
        
        return self.collection.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": filtered_data}
        )
