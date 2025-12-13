"""QR routes."""
from flask import Blueprint, request, send_file
from app.infrastructure.repositories import UserRepository
from app.domain.services import QRService
from app.domain.services_interfaces import IQRService
from app.presentation.utils.middleware import token_required, rate_limit, handle_mongodb_errors
from app.presentation.utils.response import ResponseBuilder
from app.application.dto.qr_dto import QRDTO
from app.presentation.config import TALLY_FORM_URL
from bson import ObjectId
import logging

qr_bp = Blueprint('qr', __name__)
user_repository = UserRepository()
qr_service: IQRService = QRService()


@qr_bp.route('/generate-qr', methods=['POST'])
@token_required
@rate_limit(limit=10, window=3600)
def generate_qr():
    try:
        dto = QRDTO.from_request(request)

        try:
            shop_id_obj = ObjectId(dto.shop_id)
        except:
            return ResponseBuilder.error("معرف المتجر غير صحيح", 400)

        user = user_repository.find_by_id(shop_id_obj)
        if not user:
            return ResponseBuilder.error("المتجر غير موجود", 404)

        shop_name = user.shop_name or ''

        qr_base64 = qr_service.generate_qr_with_type(dto.shop_id, dto.shop_type, shop_name)

        if not qr_base64:
            return ResponseBuilder.error("فشل في إنشاء رمز QR", 500)

        # Note: update_qr_code not implemented in UserRepository yet
        # For now, we'll just return the QR code
        # TODO: Implement update_qr_code in UserRepository

        return ResponseBuilder.success({
            "qr_code": qr_base64,
            "shop_type": dto.shop_type,
            "shop_name": shop_name
        }, "تم إنشاء رمز QR بنجاح", 201)

    except Exception as e:
        error_message = handle_mongodb_errors(e)
        logging.error(f"QR generation failed: {e}")
        return ResponseBuilder.error(error_message, 400)


@qr_bp.route('/qr/<shop_id>', methods=['GET'])
def get_qr(shop_id):
    try:
        user = user_repository.find_by_id(ObjectId(shop_id))
        if not user:
            return ResponseBuilder.error("المتجر غير موجود", 404)

        shop_type = user.shop_type or 'عام'
        shop_name = user.shop_name or 'حاسر السمعة'

        # QR code generation (qr_code field not in Domain User model yet)
        qr_base64 = qr_service.generate_qr_with_type(shop_id, shop_type, shop_name)

        url = f"{TALLY_FORM_URL}?shop_id={shop_id}&shop_type={shop_type}&shop_name={shop_name}"

        return ResponseBuilder.success({
            "qr_code": qr_base64,
            "url": url,
            "shop_type": shop_type,
            "shop_name": user.shop_name or 'Unknown Shop'
        }, "تم جلب رمز QR بنجاح", 200)

    except Exception as e:
        logging.error(f"QR retrieval failed: {e}")
        return ResponseBuilder.error("فشل في جلب رمز QR", 500)
