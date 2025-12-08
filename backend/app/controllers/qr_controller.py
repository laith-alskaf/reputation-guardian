from flask import Blueprint, request
from app.models.user import UserModel
from app.services.core import QRService
from app.services_interfaces import IQRService
from app.utils.middleware import token_required, rate_limit, handle_mongodb_errors
from app.utils.response import ResponseBuilder
from app.dto.qr_dto import QRDTO
from app.config import TALLY_FORM_URL
from bson import ObjectId
import logging

qr_bp = Blueprint('qr', __name__)
user_model = UserModel()
qr_service: IQRService = QRService()
@qr_bp.route('/generate-qr', methods=['POST'])
@token_required
@rate_limit(limit=10, window=3600)
def generate_qr():
    try:
        dto = QRDTO.from_request(request)

        try:
            ObjectId(dto.shop_id)
        except:
            return ResponseBuilder.error("معرف المتجر غير صحيح", 400)

        user = user_model.find_by_id(dto.shop_id)
        if not user:
            return ResponseBuilder.error("المتجر غير موجود", 404)

        shop_name = user.get('shop_name', '')

        qr_base64 = qr_service.generate_qr_with_type(dto.shop_id, dto.shop_type, shop_name)

        if not qr_base64:
            return ResponseBuilder.error("فشل في إنشاء رمز QR", 500)

        update_result = user_model.update_qr_code(dto.shop_id, qr_base64)

        if update_result.matched_count == 0:
            return ResponseBuilder.error("المتجر غير موجود", 404)

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
        user = user_model.find_by_id(shop_id)
        if not user:
            return ResponseBuilder.error("المتجر غير موجود", 404)

        shop_type = user.get('shop_type', 'عام')
        shop_name = user.get('shop_name', 'حاسر السمعة')

        qr_base64 = user.get('qr_code')
        if not qr_base64:
            qr_base64 = qr_service.generate_qr_with_type(shop_id, shop_type, shop_name)

        url = f"{TALLY_FORM_URL}?shop_id={shop_id}&shop_type={shop_type}&shop_name={shop_name}"

        return ResponseBuilder.success({
            "qr_code": qr_base64,
            "url": url,
            "shop_type": shop_type,
            "shop_name": user.get('shop_name', 'Unknown Shop')
        }, "تم جلب رمز QR بنجاح", 200)

    except Exception as e:
        logging.error(f"QR retrieval failed: {e}")
        return ResponseBuilder.error("فشل في جلب رمز QR", 500)
