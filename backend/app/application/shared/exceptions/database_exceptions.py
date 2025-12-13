"""Database exceptions."""
from .base_exception import AppException

class DatabaseException(AppException):
    """Base database exception."""
    def __init__(self, message: str = "خطأ في قاعدة البيانات"):
        super().__init__(message, status_code=500)

class RecordNotFoundException(DatabaseException):
    """Raised when a record is not found."""
    def __init__(self, message: str = "السجل غير موجود"):
        super().__init__(message, status_code=404)

class DuplicateRecordException(DatabaseException):
    """Raised when trying to create duplicate record."""
    def __init__(self, message: str = "السجل موجود مسبقاً"):
        super().__init__(message, status_code=409)
