from flask import request, jsonify
from functools import wraps
import jwt
from config import SECRET_KEY
import logging

def token_required(f):
    """
    JWT token authentication middleware
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = None

        # Extract token from header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]

        # Extract token from query parameter (for GET requests)
        if not token and 'token' in request.args:
            token = request.args.get('token')

        if not token:
            return jsonify({'error': 'Token is missing'}), 401

        try:
            # Decode the token
            payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])

            # Add user info to request context
            request.user_id = payload.get('user_id')  # For backward compatibility
            request.shop_id = payload.get('shop_id')
            request.email = payload.get('email')
            request.shop_type = payload.get('shop_type')

        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token'}), 401
        except Exception as e:
            logging.error(f"Token validation error: {e}")
            return jsonify({'error': 'Token validation failed'}), 401

        return f(*args, **kwargs)

    return decorated_function

def optional_token(f):
    """
    Optional JWT token - doesn't fail if missing
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = None

        # Extract token from header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]

        # Extract token from query parameter
        if not token and 'token' in request.args:
            token = request.args.get('token')

        if token:
            try:
                payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
                request.user_id = payload.get('user_id')
                request.shop_id = payload.get('shop_id')
                request.email = payload.get('email')
                request.shop_type = payload.get('shop_type')
                request.authenticated = True
            except:
                request.authenticated = False
        else:
            request.authenticated = False

        return f(*args, **kwargs)

    return decorated_function

def validate_input(data, required_fields=None, optional_fields=None):
    """
    Input validation and sanitization
    """
    if not data:
        return {'valid': False, 'error': 'No data provided'}

    validated_data = {}

    # Check required fields
    if required_fields:
        for field in required_fields:
            if field not in data or not data[field]:
                return {'valid': False, 'error': f'Missing required field: {field}'}
            validated_data[field] = sanitize_input(data[field])

    # Add optional fields if present
    if optional_fields:
        for field in optional_fields:
            if field in data:
                validated_data[field] = sanitize_input(data[field])

    return {'valid': True, 'data': validated_data}

def sanitize_input(value):
    """
    Basic input sanitization
    """
    if isinstance(value, str):
        # Remove potential XSS characters
        value = value.strip()
        # Basic sanitization - you might want to use bleach library for more comprehensive sanitization
        dangerous_chars = ['<', '>', '&', '"', "'"]
        for char in dangerous_chars:
            value = value.replace(char, '')

    return value

def rate_limit(limit=100, window=3600):
    """
    Simple rate limiting decorator (basic implementation)
    In production, use flask-limiter or similar
    """
    def decorator(f):
        @wraps(f)
        def wrapped(*args, **kwargs):
            # Basic rate limiting logic (you should implement proper rate limiting)
            # For now, just pass through
            return f(*args, **kwargs)
        return wrapped
    return decorator

def handle_mongodb_errors(error):
    """
    Handle MongoDB errors and return user-friendly Arabic messages
    """
    error_message = str(error)

    # Duplicate key errors
    if 'E11000' in error_message or 'duplicate key' in error_message.lower():
        if 'email' in error_message:
            return 'البريد الإلكتروني مستخدم مسبقاً'
        elif 'shop_id' in error_message:
            return 'معرف المتجر مستخدم مسبقاً'
        else:
            return 'البيانات موجودة مسبقاً في قاعدة البيانات'

    # Document validation errors
    if 'Document failed validation' in error_message:
        return parse_validation_error(error_message)

    # Connection errors
    if 'connection' in error_message.lower():
        return 'خطأ في الاتصال بقاعدة البيانات'

    # Timeout errors
    if 'timeout' in error_message.lower():
        return 'انتهت مهلة العملية، يرجى المحاولة مرة أخرى'

    # Generic database error
    return 'حدث خطأ في قاعدة البيانات'

def parse_validation_error(error_message):
    """
    Parse MongoDB validation error and return user-friendly message
    """
    # Common validation error patterns
    if 'email' in error_message and 'pattern' in error_message:
        return 'يرجى إدخال بريد إلكتروني صحيح'

    if 'password' in error_message and 'minLength' in error_message:
        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'

    if 'shop_name' in error_message:
        if 'minLength' in error_message:
            return 'اسم المتجر يجب أن يكون حرفين على الأقل'
        if 'maxLength' in error_message:
            return 'اسم المتجر يجب أن يكون أقل من 100 حرف'

    if 'shop_type' in error_message and 'enum' in error_message:
        return 'يرجى اختيار نوع متجر صحيح من القائمة'

    if 'stars' in error_message:
        if 'minimum' in error_message:
            return 'عدد النجوم يجب أن يكون بين 1 و 5'
        if 'maximum' in error_message:
            return 'عدد النجوم يجب أن يكون بين 1 و 5'

    if 'required' in error_message:
        missing_fields = extract_missing_fields(error_message)
        if missing_fields:
            return f'الحقول التالية مطلوبة: {", ".join(missing_fields)}'

    # Generic validation error
    return 'البيانات المدخلة لا تطابق المتطلبات'

def extract_missing_fields(error_message):
    """
    Extract missing required fields from validation error
    """
    missing_fields = []
    field_mappings = {
        'email': 'البريد الإلكتروني',
        'password': 'كلمة المرور',
        'shop_name': 'اسم المتجر',
        'shop_type': 'نوع المتجر',
        'stars': 'عدد النجوم',
        'overall_sentiment': 'تحليل المشاعر',
        'shop_id': 'معرف المتجر',
        'text': 'نص التقييم'
    }

    for field, arabic_name in field_mappings.items():
        if field in error_message and 'required' in error_message:
            missing_fields.append(arabic_name)

    return missing_fields

def safe_db_operation(operation_func):
    """
    Decorator to safely execute database operations with error handling
    """
    def wrapper(*args, **kwargs):
        try:
            return operation_func(*args, **kwargs)
        except Exception as e:
            logging.error(f"Database operation failed: {e}")
            user_friendly_error = handle_mongodb_errors(e)
            raise ValueError(user_friendly_error)
    return wrapper

def handle_mongodb_errors(error):
    """
    Handle MongoDB errors and return user-friendly Arabic messages
    """
    error_message = str(error)

    # Duplicate key errors
    if 'E11000' in error_message or 'duplicate key' in error_message.lower():
        if 'email' in error_message:
            return 'البريد الإلكتروني مستخدم مسبقاً'
        elif 'shop_id' in error_message:
            return 'معرف المتجر مستخدم مسبقاً'
        else:
            return 'البيانات موجودة مسبقاً في قاعدة البيانات'

    # Document validation errors
    if 'Document failed validation' in error_message:
        return parse_validation_error(error_message)

    # Connection errors
    if 'connection' in error_message.lower():
        return 'خطأ في الاتصال بقاعدة البيانات'

    # Timeout errors
    if 'timeout' in error_message.lower():
        return 'انتهت مهلة العملية، يرجى المحاولة مرة أخرى'

    # Generic database error
    return 'حدث خطأ في قاعدة البيانات'

def parse_validation_error(error_message):
    """
    Parse MongoDB validation error and return user-friendly message
    """
    # Common validation error patterns
    if 'email' in error_message and 'pattern' in error_message:
        return 'يرجى إدخال بريد إلكتروني صحيح'

    if 'password' in error_message and 'minLength' in error_message:
        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'

    if 'shop_name' in error_message:
        if 'minLength' in error_message:
            return 'اسم المتجر يجب أن يكون حرفين على الأقل'
        if 'maxLength' in error_message:
            return 'اسم المتجر يجب أن يكون أقل من 100 حرف'

    if 'shop_type' in error_message and 'enum' in error_message:
        return 'يرجى اختيار نوع متجر صحيح من القائمة'

    if 'stars' in error_message:
        if 'minimum' in error_message:
            return 'عدد النجوم يجب أن يكون بين 1 و 5'
        if 'maximum' in error_message:
            return 'عدد النجوم يجب أن يكون بين 1 و 5'

    if 'required' in error_message:
        missing_fields = extract_missing_fields(error_message)
        if missing_fields:
            return f'الحقول التالية مطلوبة: {", ".join(missing_fields)}'

    # Generic validation error
    return 'البيانات المدخلة لا تطابق المتطلبات'

def extract_missing_fields(error_message):
    """
    Extract missing required fields from validation error
    """
    missing_fields = []
    field_mappings = {
        'email': 'البريد الإلكتروني',
        'password': 'كلمة المرور',
        'shop_name': 'اسم المتجر',
        'shop_type': 'نوع المتجر',
        'stars': 'عدد النجوم',
        'overall_sentiment': 'تحليل المشاعر',
        'shop_id': 'معرف المتجر',
        'text': 'نص التقييم'
    }

    for field, arabic_name in field_mappings.items():
        if field in error_message and 'required' in error_message:
            missing_fields.append(arabic_name)

    return missing_fields

def safe_db_operation(operation_func, error_message="حدث خطأ في قاعدة البيانات"):
    """
    Decorator to safely execute database operations with error handling
    """
    def wrapper(*args, **kwargs):
        try:
            return operation_func(*args, **kwargs)
        except Exception as e:
            logger.error(f"Database operation failed: {e}")
            user_friendly_error = handle_mongodb_errors(e)
            raise ValueError(user_friendly_error)
