from flask import Blueprint, request, jsonify
from app.models.user import UserModel
from app.config import SECRET_KEY, SHOP_TYPES
from app.utils.middleware import token_required, handle_mongodb_errors
import jwt
import datetime
from datetime import timezone
import logging
import re

auth_bp = Blueprint('auth', __name__)
user_model = UserModel()

@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        data = request.json
        required_fields = ['email', 'password', 'shop_name', 'shop_type']

        if not data or not all(data.get(field) for field in required_fields):
            missing_fields = [field for field in required_fields if not data.get(field)]
            arabic_fields = {
                'email': 'البريد الإلكتروني',
                'password': 'كلمة المرور',
                'shop_name': 'اسم المتجر',
                'shop_type': 'نوع المتجر'
            }
            missing_arabic = [arabic_fields[field] for field in missing_fields]
            return jsonify({"error": f"الحقول التالية مطلوبة: {', '.join(missing_arabic)}"}), 400

        if data['shop_type'] not in SHOP_TYPES:
            return jsonify({"error": "يرجى اختيار نوع متجر صحيح من القائمة"}), 400

        if not re.match(r'^[^@\s]+@[^@\s]+\.[^@\s]+$', data['email']):
            return jsonify({"error": "يرجى إدخال بريد إلكتروني صحيح"}), 400

        if len(data['password']) < 6:
            return jsonify({"error": "كلمة المرور يجب أن تكون 6 أحرف على الأقل"}), 400

        if len(data['shop_name'].strip()) < 2:
            return jsonify({"error": "اسم المتجر يجب أن يكون حرفين على الأقل"}), 400

        shop_id = user_model.create_user(
            data['email'],
            data['password'],
            data['shop_name'],
            data['shop_type'],
            data.get('device_token', '')
        )

        token = jwt.encode({
            "email": data['email'].lower().strip(),
            "shop_id": shop_id,
            "shop_type": data['shop_type'],
            "exp": datetime.datetime.now(timezone.utc) + datetime.timedelta(days=30)
        }, SECRET_KEY, algorithm="HS256")

        return jsonify({
            "token": token,
            "shop_id": shop_id,
            "shop_type": data['shop_type'],
            "message": "تم إنشاء الحساب بنجاح"
        }), 201

    except Exception as e:
        error_message = handle_mongodb_errors(e)
        logging.error(f"Registration failed: {e}")
        return jsonify({"error": error_message}), 400

@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.json
        if not data or not data.get('email') or not data.get('password'):
            return jsonify({"error": "البريد الإلكتروني وكلمة المرور مطلوبان"}), 400

        if not re.match(r'^[^@\s]+@[^@\s]+\.[^@\s]+$', data['email']):
            return jsonify({"error": "يرجى إدخال بريد إلكتروني صحيح"}), 400

        user = user_model.find_by_email(data['email'])

        if not user:
            return jsonify({"error": "البريد الإلكتروني أو كلمة المرور غير صحيحة"}), 401

        if not user_model.verify_password(user['password'], data['password']):
            return jsonify({"error": "البريد الإلكتروني أو كلمة المرور غير صحيحة"}), 401

        token = jwt.encode({
            "email": user['email'],
            "shop_id": str(user['_id']),
            "shop_type": user.get('shop_type', ''),
            "exp": datetime.datetime.now(timezone.utc) + datetime.timedelta(days=30)
        }, SECRET_KEY, algorithm="HS256")

        return jsonify({
            "token": token,
            "shop_id": str(user['_id']),
            "shop_type": user.get('shop_type', ''),
            "message": "تم تسجيل الدخول بنجاح"
        }), 200

    except Exception as e:
        error_message = handle_mongodb_errors(e)
        logging.error(f"Login failed: {e}")
        return jsonify({"error": error_message}), 400

@auth_bp.route('/profile', methods=['GET'])
@token_required
def get_profile():
    try:
        shop_id = request.shop_id
        user = user_model.find_by_id(shop_id)

        if not user:
            return jsonify({"error": "المستخدم غير موجود"}), 404

        user_data = {
            "shop_id": str(user['_id']),
            "email": user.get('email'),
            "shop_name": user.get('shop_name'),
            "shop_type": user.get('shop_type'),
            "created_at": user.get('created_at'),
            "qr_code": user.get('qr_code'),
            "qr_updated_at": user.get('qr_updated_at')
        }

        return jsonify(user_data), 200

    except Exception as e:
        error_message = handle_mongodb_errors(e)
        logging.error(f"Profile retrieval failed: {e}")
        return jsonify({"error": error_message}), 400

@auth_bp.route('/logout', methods=['POST'])
@token_required
def logout():
    try:
        return jsonify({"message": "تم تسجيل الخروج بنجاح"}), 200
    except Exception as e:
        logging.error(f"Logout failed: {e}")
        return jsonify({"error": "حدث خطأ في تسجيل الخروج"}), 400
