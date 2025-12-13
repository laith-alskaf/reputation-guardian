"""Authentication and authorization exceptions."""
from .base_exception import AppException

class AuthException(AppException):
    """Base authentication exception."""
    pass

class InvalidCredentialsException(AuthException):
    """Raised when login credentials are invalid."""
    def __init__(self, message: str = "البريد الإلكتروني أو كلمة المرور غير صحيحة"):
        super().__init__(message, status_code=401)

class UserAlreadyExistsException(AuthException):
    """Raised when trying to register with existing email."""
    def __init__(self, message: str = "هذا البريد الإلكتروني مسجل مسبقاً"):
        super().__init__(message, status_code=409)

class UnauthorizedException(AuthException):
    """Raised when user is not authorized."""
    def __init__(self, message: str = "غير مصرح لك بالوصول"):
        super().__init__(message, status_code=403)

class TokenExpiredException(AuthException):
    """Raised when JWT token has expired."""
    def __init__(self, message: str = "انتهت صلاحية الجلسة"):
        super().__init__(message, status_code=401)

class InvalidTokenException(AuthException):
    """Raised when JWT token is invalid."""
    def __init__(self, message: str = "رمز الجلسة غير صالح"):
        super().__init__(message, status_code=401)
