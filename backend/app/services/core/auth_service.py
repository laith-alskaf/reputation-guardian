# app/services/auth_service.py
from app.services_interfaces import IAuthService
from app.models.user import UserModel
from app.config import SECRET_KEY
import jwt, datetime
from datetime import timezone
from app.utils.time_utils import get_syria_time

class AuthService(IAuthService):
    def __init__(self):
        self.user_model = UserModel()

    def register(self, email, password, shop_name, shop_type, device_token=""):
        existing_user = self.user_model.find_by_email(email)
        if existing_user:
            raise LookupError("هذا البريد الإلكتروني مسجل مسبقًا")
        shop_id = self.user_model.create_user(email, password, shop_name, shop_type, device_token)
        token = jwt.encode({
            "email": email,
            "shop_id": shop_id,
            "shop_type": shop_type,
            "shop_name": shop_name,
            "exp": (get_syria_time() + datetime.timedelta(days=30)).timestamp()
        }, SECRET_KEY, algorithm="HS256")
        return {"token": token, "shop_id": shop_id, "shop_type": shop_type ,"shop_name":shop_name}

    def login(self, email, password):
        user = self.user_model.find_by_email(email)
        if not user or not self.user_model.verify_password(user["password"], password):
          raise  ValueError("كلمة المرور غير صحيحة")
        token = jwt.encode({
            "email": user["email"],
            "shop_id": str(user["_id"]),
            "shop_type": user.get("shop_type", ""),
            "shop_name": user.get("shop_name", ""),
            "exp": (get_syria_time() + datetime.timedelta(days=30)).timestamp()
        }, SECRET_KEY, algorithm="HS256")
        return {"token": token, "shop_id": str(user["_id"]), "shop_type": user.get("shop_type", ""),"shop_name":user.get("shop_name", "")}

    def logout(self):
        # Client-side logout, no server-side action needed
        pass
