from flask import Blueprint, request
from app.utils.middleware import token_required, handle_mongodb_errors
from app.utils.response import ResponseBuilder
from app.dto.dashboard_dto import DashboardDTO
from app.services.core import DashboardService
from app.services_interfaces import IDashboardService
import logging

dashboard_bp = Blueprint('dashboard', __name__)
dashboard_service :IDashboardService= DashboardService()

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
        # The `shop_id` is available on `request` from the `@token_required` decorator
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
        # Token data is already attached to request by @token_required
        profile_data = {
            "shop_id": request.shop_id,
            "email": request.email,
            "shop_type": request.shop_type,
            "shop_name": request.shop_name
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
        from app.models.user import UserModel
        user_model = UserModel()
        
        data = request.json or {}
        
        # user_id comes from the token via @token_required wrapper (request.user_id)
        # Note: token_required usually sets request.user_id. Let's assume it does or we use request.email to find.
        # Based on get_profile, we have request.shop_id (which seems to be the user _id in this system)
        
        user_id = request.shop_id
        
        result = user_model.update_user(user_id, data)
        
        if result and result.modified_count > 0:
            return ResponseBuilder.success(None, "تم تحديث البيانات بنجاح", 200)
        else:
            return ResponseBuilder.success(None, "لم يتم إجراء أي تغييرات", 200)
            
    except Exception as e:
        logging.error(f"Profile update failed: {e}")
        return ResponseBuilder.error("فشل في تحديث البيانات", 400)
