"""Validation exceptions."""
from .base_exception import AppException

class ValidationException(AppException):
    """Base validation exception."""
    def __init__(self, message: str = "خطأ في التحقق من البيانات"):
        super().__init__(message, status_code=400)

class InvalidEmailException(ValidationException):
    """Raised when email format is invalid."""
    def __init__(self, message: str = "صيغة البريد الإلكتروني غير صحيحة"):
        super().__init__(message)

class WeakPasswordException(ValidationException):
    """Raised when password doesn't meet requirements."""
    def __init__(self, message: str = "كلمة المرور يجب أن تكون 8 أحرف على الأقل"):
        super().__init__(message)

class MissingFieldException(ValidationException):
    """Raised when required field is missing."""
    def __init__(self, field_name: str):
        message = f"الحقل '{field_name}' مطلوب"
        super().__init__(message)

class InvalidShopTypeException(ValidationException):
    """Raised when shop type is invalid."""
    def __init__(self, message: str = "نوع المتجر غير صالح"):
        super().__init__(message)
