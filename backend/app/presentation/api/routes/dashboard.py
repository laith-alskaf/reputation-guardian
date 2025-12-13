"""Dashboard routes."""
from flask import Blueprint, request, jsonify
from app.presentation.utils.middleware import token_required, handle_mongodb_errors
from app.presentation.utils.response import ResponseBuilder
from app.application.dto.dashboard_dto import DashboardDTO
from app.application.services import DashboardService
from app.domain.services_interfaces import IDashboardService
import logging

dashboard_bp = Blueprint('dashboard', __name__)
dashboard_service: IDashboardService = DashboardService()


@dashboard_bp.route('/dashboard', methods=['GET'])
@token_required
def get_dashboard():
    try:
        dto = DashboardDTO.from_request(request)

        dashboard_data = dashboard_service.get_dashboard_data(dto.shop_id, request.email, request.shop_type)
        if not dashboard_data:
            return ResponseBuilder.error("المتجر غير موجود", 404)

        return ResponseBuilder.success(dashboard_data, "تم جلب بيانات لوحة التحكم", 200)

    except Exception as e:
        error_message = handle_mongodb_errors(e)
        logging.error(f"Dashboard retrieval failed: {e}")
        return ResponseBuilder.error(error_message, 400)


@dashboard_bp.route('/dashboard/rejected', methods=['GET'])
@token_required
def get_rejected_dashboard():
    try:
        rejected_data = dashboard_service.get_rejected_reviews(request.shop_id)
        return ResponseBuilder.success(rejected_data, "تم جلب التقييمات المرفوضة", 200)

    except Exception as e:
        error_message = handle_mongodb_errors(e)
        logging.error(f"Rejected reviews retrieval failed: {e}")
        return ResponseBuilder.error(error_message, 400)


@dashboard_bp.route('/profile', methods=['GET'])
@token_required
def get_profile():
    """Get user profile information"""
    try:
        from app.infrastructure.repositories import UserRepository
        from bson import ObjectId
        
        user_repository = UserRepository()
        user = user_repository.find_by_id(ObjectId(request.shop_id))
        
        if not user:
             return ResponseBuilder.error("المستخدم غير موجود", 404)

        profile_data = {
            "shop_id": str(user.id),
            "email": user.email,
            "shop_type": user.shop_type,
            "shop_name": user.shop_name,
            "telegram_chat_id": user.telegram_chat_id,
            "device_token": user.device_token
        }
        
        return ResponseBuilder.success(profile_data, "تم جلب معلومات الحساب", 200)
    
    except Exception as e:
        logging.error(f"Profile retrieval failed: {e}")
        return ResponseBuilder.error("فشل في جلب معلومات الحساب", 400)


@dashboard_bp.route('/profile', methods=['PUT'])
@token_required
def update_profile():
    """تحديث معلومات المستخدم"""
    try:
        from app.infrastructure.repositories import UserRepository
        from bson import ObjectId
        
        user_repository = UserRepository()
        data = request.json or {}
        user_id = ObjectId(request.shop_id)
        
        result = user_repository.update_user(user_id, data)
        
        if result and result.modified_count > 0:
            return ResponseBuilder.success(None, "تم تحديث البيانات بنجاح", 200)
        else:
            return ResponseBuilder.success(None, "لم يتم إجراء أي تغييرات", 200)
            
    except Exception as e:
        logging.error(f"Profile update failed: {e}")
        return ResponseBuilder.error("فشل في تحديث البيانات", 400)
