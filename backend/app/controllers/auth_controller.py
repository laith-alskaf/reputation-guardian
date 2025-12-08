from flask import Blueprint, request
from app.services.core import AuthService
from app.services_interfaces import IAuthService
from app.utils.response import ResponseBuilder
from app.dto.user_dto import RegisterDTO,LoginDTO
import logging
import pymongo

auth_bp = Blueprint('auth', __name__)
auth_service: IAuthService = AuthService()  # استخدام الواجهة مع الخدمة

@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        data = request.json or {}
        dto = RegisterDTO.from_dict(data)

        result = auth_service.register(
            email=dto.email,
            password=dto.password,
            shop_name=dto.shop_name,
            shop_type=dto.shop_type,
            device_token=dto.device_token or ""
        )
        return ResponseBuilder.success(result, "تم التسجيل بنجاح", 201)


    except LookupError as e:
        logging.warning(f"Duplicate email: {e}")
        return ResponseBuilder.error(str(e), 400)
    except ValueError as e:
        logging.warning(f"Validation error: {e}")
        return ResponseBuilder.error(str(e), 400)
    except pymongo.errors.WriteError as e:
        logging.error(f"Mongo validation error: {e}", exc_info=True)
        return ResponseBuilder.error("نوع المتجر غير صالح، يرجى اختيار قيمة صحيحة", 400)
    except Exception as e:
        logging.error(f"Register error: {e}", exc_info=True)
        return ResponseBuilder.error("Internal server error", 500)



@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.json or {}
        dto = LoginDTO.from_dict(data)

        result = auth_service.login(
            email=dto.email,
            password=dto.password
        )
        return ResponseBuilder.success(result, "تم تسجيل الدخول بنجاح", 200)

    except LookupError as e:
        logging.warning(f"Login failed: {e}")
        return ResponseBuilder.error(str(e), 401)
    except ValueError as e:
        logging.warning(f"Password error: {e}")
        return ResponseBuilder.error(str(e), 400)
    except Exception as e:
        logging.error(f"Login error: {e}", exc_info=True)
        return ResponseBuilder.error("Internal server error", 500)

@auth_bp.route('/logout', methods=['POST'])
def logout():
    try:
        # Since logout is handled client-side, just return success
        return ResponseBuilder.success(None, "تم تسجيل الخروج بنجاح", 200)
    except Exception as e:
        logging.error(f"Logout error: {e}", exc_info=True)
        return ResponseBuilder.error("Internal server error", 500)
