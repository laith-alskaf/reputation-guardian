"""Authentication routes."""
from flask import Blueprint, request
from app.application.services import AuthService
from app.domain.services_interfaces import IAuthService
from app.presentation.utils.response import ResponseBuilder
from app.application.dto.user_dto import RegisterDTO, LoginDTO

auth_bp = Blueprint('auth', __name__)
auth_service: IAuthService = AuthService()


@auth_bp.route('/register', methods=['POST'])
def register():
    """Register a new user."""
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


@auth_bp.route('/login', methods=['POST'])
def login():
    """Login user."""
    data = request.json or {}
    dto = LoginDTO.from_dict(data)

    result = auth_service.login(
        email=dto.email,
        password=dto.password
    )
    return ResponseBuilder.success(result, "تم تسجيل الدخول بنجاح", 200)


@auth_bp.route('/logout', methods=['POST'])
def logout():
    """Logout user (client-side)."""
    return ResponseBuilder.success(None, "تم تسجيل الخروج بنجاح", 200)
