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
            "shop_name": getattr(request, 'shop_name', None)
        }
        
        return ResponseBuilder.success(profile_data, "تم جلب معلومات الحساب", 200)
    
    except Exception as e:
        logging.error(f"Profile retrieval failed: {e}")
        return ResponseBuilder.error("فشل في جلب معلومات الحساب", 400)