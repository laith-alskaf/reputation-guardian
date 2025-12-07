from flask import Flask, request, jsonify
from flask_cors import CORS
from mongo_connection import connect_to_mongodb
import jwt
import bcrypt
from config import SECRET_KEY, SHOP_TYPES
import datetime
from datetime import timezone
import logging
from middleware import token_required, validate_input, rate_limit, handle_mongodb_errors
from qr_generator import generate_qr_with_type
from bson import ObjectId
import json
from sentiment_analysis import clean_text, analyze_sentiment, analyze_toxicity, classify_review, detect_review_quality
from deepseek_integration import organize_customer_feedback, determine_overall_sentiment
from notifications import initialize_firebase, send_fcm_notification, send_telegram_notification
class JSONEncoder(json.JSONEncoder):
    """Custom JSON encoder to handle ObjectId and datetime"""
    def default(self, obj):
        if isinstance(obj, ObjectId):
            return str(obj)
        if isinstance(obj, datetime.datetime):
            return obj.isoformat()
        return super().default(obj)

app = Flask(__name__)
app.json_encoder = JSONEncoder
db = connect_to_mongodb()
users = db['users']
reviews = db['reviews']
initialize_firebase()

def convert_object_ids(obj):
    """
    Recursively convert all ObjectId instances to strings in nested data structures
    """
    if isinstance(obj, ObjectId):
        return str(obj)
    elif isinstance(obj, dict):
        return {key: convert_object_ids(value) for key, value in obj.items()}
    elif isinstance(obj, list):
        return [convert_object_ids(item) for item in obj]
    elif isinstance(obj, datetime.datetime):
        return obj.isoformat()
    else:
        return obj
# Enable CORS
CORS(app, origins=["http://localhost:3000", "http://localhost:5000", "https://your-frontend-domain.com"])

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)

@app.route('/')
def health():
    return jsonify({"status": "حارس السمعة يعمل بكفاءة 🛡️", "version": "2.0"}), 200

@app.route('/register', methods=['POST'])
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

        # Validate shop_type
        if data['shop_type'] not in SHOP_TYPES:
            return jsonify({"error": "يرجى اختيار نوع متجر صحيح من القائمة"}), 400

        # Validate email format
        import re
        if not re.match(r'^[^@\s]+@[^@\s]+\.[^@\s]+$', data['email']):
            return jsonify({"error": "يرجى إدخال بريد إلكتروني صحيح"}), 400

        # Validate password length
        if len(data['password']) < 6:
            return jsonify({"error": "كلمة المرور يجب أن تكون 6 أحرف على الأقل"}), 400

        # Validate shop_name length
        if len(data['shop_name'].strip()) < 2:
            return jsonify({"error": "اسم المتجر يجب أن يكون حرفين على الأقل"}), 400

        # Hash password
        hashed_pw = bcrypt.hashpw(data['password'].encode('utf-8'), bcrypt.gensalt())

        # Insert user
        user_data = {
            "email": data['email'].lower().strip(),
            "password": hashed_pw,
            "shop_name": data['shop_name'].strip(),
            "shop_type": data['shop_type'],
            "device_token": data.get('device_token', '').strip(),
            "created_at": datetime.datetime.now(timezone.utc)
        }

        result = users.insert_one(user_data)

        # Generate JWT
        token = jwt.encode({
            "email": user_data['email'],
            "shop_id": str(result.inserted_id),
            "shop_type": user_data['shop_type'],
            "exp": datetime.datetime.now(timezone.utc) + datetime.timedelta(days=30)
        }, SECRET_KEY, algorithm="HS256")

        return jsonify({
            "token": token,
            "shop_id": str(result.inserted_id),
            "shop_type": user_data['shop_type'],
            "message": "تم إنشاء الحساب بنجاح"
        }), 201

    except Exception as e:
        error_message = handle_mongodb_errors(e)
        logging.error(f"Registration failed: {e}")
        return jsonify({"error": error_message}), 400

@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.json
        if not data or not data.get('email') or not data.get('password'):
            return jsonify({"error": "البريد الإلكتروني وكلمة المرور مطلوبان"}), 400

        # Validate email format
        import re
        if not re.match(r'^[^@\s]+@[^@\s]+\.[^@\s]+$', data['email']):
            return jsonify({"error": "يرجى إدخال بريد إلكتروني صحيح"}), 400

        user = users.find_one({"email": data['email'].lower().strip()})

        if not user:
            return jsonify({"error": "البريد الإلكتروني أو كلمة المرور غير صحيحة"}), 401

        # Check password
        if not bcrypt.checkpw(data['password'].encode('utf-8'), user['password']):
            return jsonify({"error": "البريد الإلكتروني أو كلمة المرور غير صحيحة"}), 401

        # Generate JWT
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

@app.route('/generate-qr', methods=['POST'])
@token_required
@rate_limit(limit=10, window=3600)  # 10 QR generations per hour
def generate_qr():
    """
    Generate and store QR code for authenticated user
    """
    try:
        # Get user info from token (added by middleware)
        shop_id = request.shop_id
        shop_type = request.shop_type

        # Validate shop_id format
        try:
            ObjectId(shop_id)
        except:
            return jsonify({"error": "معرف المتجر غير صحيح"}), 400

        # Generate QR with shop type
        qr_base64 = generate_qr_with_type(shop_id, shop_type)

        if not qr_base64:
            return jsonify({"error": "فشل في إنشاء رمز QR"}), 500

        # Store QR in database
        qr_data = {
            "shop_id": shop_id,
            "qr_code": qr_base64,
            "shop_type": shop_type,
            "created_at": datetime.datetime.now(timezone.utc),
            "is_active": True
        }

        # Update user with QR info
        update_result = users.update_one(
            {"_id": ObjectId(shop_id)},
            {"$set": {"qr_code": qr_base64, "qr_updated_at": datetime.datetime.now(timezone.utc)}}
        )

        if update_result.matched_count == 0:
            return jsonify({"error": "المتجر غير موجود"}), 404

        # Optional: Store in separate qr_codes collection
        qr_collection = db['qr_codes']
        qr_collection.insert_one(qr_data)

        return jsonify({
            "success": True,
            "qr_code": qr_base64,
            "shop_type": shop_type,
            "message": "تم إنشاء رمز QR بنجاح"
        }), 201

    except Exception as e:
        error_message = handle_mongodb_errors(e)
        logging.error(f"QR generation failed: {e}")
        return jsonify({"error": error_message}), 400

@app.route('/qr/<shop_id>', methods=['GET'])
def get_qr(shop_id):
    """
    Get QR code for a shop (public endpoint for Tally.so integration)
    """
    try:
        # Get shop type from database
        user = users.find_one({"_id": ObjectId(shop_id)})
        if not user:
            return jsonify({"error": "Shop not found"}), 404

        shop_type = user.get('shop_type', 'عام')
        shop_name = user.get('shop_name', 'حاسر السمعة')

        # Generate QR with type (or get stored one)
        qr_base64 = user.get('qr_code')
        if not qr_base64:
            # Generate new QR if not stored
            qr_base64 = generate_qr_with_type(shop_id, shop_type)

        url = f"https://tally.so/r/b5ZPV2?shop_id={shop_id}&shop_type={shop_type}&shop_name={shop_name}"

        return jsonify({
            "qr_code": qr_base64,
            "url": url,
            "shop_type": shop_type,
            "shop_name": user.get('shop_name', 'Unknown Shop')
        }), 200

    except Exception as e:
        logging.error(f"QR retrieval failed: {e}")
        return jsonify({"error": "Failed to retrieve QR code"}), 500

@app.route('/dashboard', methods=['GET'])
@token_required
def get_dashboard():
    """
    Get dashboard data for authenticated user
    """
    try:
        shop_id = request.shop_id

        # Validate shop_id format
        try:
            ObjectId(shop_id)
        except:
            return jsonify({"error": "معرف المتجر غير صحيح"}), 400

        # Get user info first
        user = users.find_one({"_id": ObjectId(shop_id)})
        if not user:
            return jsonify({"error": "المتجر غير موجود"}), 404

        # Get all reviews for this shop
        reviews_list = list(reviews.find({"shop_id": shop_id}))

        # Calculate metrics
        total_reviews = len(reviews_list)
        if total_reviews > 0:
            avg_stars = sum(review.get('stars', 0) for review in reviews_list) / total_reviews
            negative_reviews = len([r for r in reviews_list if r.get('overall_sentiment') == 'سلبي'])
            positive_reviews = len([r for r in reviews_list if r.get('overall_sentiment') == 'إيجابي'])
        else:
            avg_stars = 0
            negative_reviews = 0
            positive_reviews = 0

        # Get recent reviews (last 10)
        recent_reviews = reviews_list[-10:] if reviews_list else []

        # Format response
        dashboard_data = {
            "shop_info": {
                "shop_id": shop_id,
                "shop_name": user.get('shop_name', request.email),
                "shop_type": user.get('shop_type', request.shop_type),
                "created_at": user.get('created_at')
            },
            "metrics": {
                "total_reviews": total_reviews,
                "average_stars": round(avg_stars, 1),
                "negative_reviews": negative_reviews,
                "positive_reviews": positive_reviews,
                "neutral_reviews": total_reviews - negative_reviews - positive_reviews
            },
            "recent_reviews": recent_reviews,
            "last_updated": datetime.datetime.now(timezone.utc).isoformat()
        }

        # Convert all ObjectId to strings for JSON serialization
        dashboard_data = convert_object_ids(dashboard_data)

        return jsonify(dashboard_data), 200

    except Exception as e:
        error_message = handle_mongodb_errors(e)
        logging.error(f"Dashboard retrieval failed: {e}")
        return jsonify({"error": error_message}), 400

@app.route('/profile', methods=['GET'])
@token_required
def get_profile():
    """
    Get user profile information
    """
    try:
        shop_id = request.shop_id

        # Validate shop_id format
        try:
            ObjectId(shop_id)
        except:
            return jsonify({"error": "معرف المتجر غير صحيح"}), 400

        user = users.find_one({"_id": ObjectId(shop_id)})

        if not user:
            return jsonify({"error": "المستخدم غير موجود"}), 404

        # Remove sensitive information
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

@app.route('/logout', methods=['POST'])
@token_required
def logout():
    """
    Logout endpoint (client-side token removal)
    """
    try:
        # In a stateless JWT system, logout is handled client-side
        # You could implement token blacklisting for better security
        return jsonify({"message": "تم تسجيل الخروج بنجاح"}), 200

    except Exception as e:
        logging.error(f"Logout failed: {e}")
        return jsonify({"error": "حدث خطأ في تسجيل الخروج"}), 400

if __name__ == "__main__":
    app.run(debug=True)
