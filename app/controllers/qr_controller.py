from flask import Blueprint, request
from app.models.user import UserModel
from app.services.qr_service import generate_qr_with_type
from app.utils.middleware import token_required, rate_limit, handle_mongodb_errors
from app.utils.response import ResponseBuilder
from app.config import TALLY_FORM_URL
from bson import ObjectId
import datetime
from datetime import timezone
import logging

qr_bp = Blueprint('qr', __name__)
user_model = UserModel()

@qr_bp.route('/generate-qr', methods=['POST'])
@token_required
@rate_limit(limit=10, window=3600)
def generate_qr():
    try:
        shop_id = request.shop_id
        shop_type = request.shop_type

        try:
            ObjectId(shop_id)
        except:
            return ResponseBuilder.error("معرف المتجر غير صحيح", 400)

        qr_base64 = generate_qr_with_type(shop_id, shop_type)

        if not qr_base64:
            return ResponseBuilder.error("فشل في إنشاء رمز QR", 500)

        # Update user with QR info
        update_result = user_model.update_qr_code(shop_id, qr_base64)

        if update_result.matched_count == 0:
            return ResponseBuilder.error("المتجر غير موجود", 404)

        return ResponseBuilder.success({
            "qr_code": qr_base64,
            "shop_type": shop_type
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
            qr_base64 = generate_qr_with_type(shop_id, shop_type)

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