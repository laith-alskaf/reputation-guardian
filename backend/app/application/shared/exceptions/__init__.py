"""Custom exceptions module."""
from .base_exception import AppException
from .auth_exceptions import (
    AuthException,
    InvalidCredentialsException,
    UserAlreadyExistsException,
    UnauthorizedException,
    TokenExpiredException,
    InvalidTokenException
)
from .validation_exceptions import (
    ValidationException,
    InvalidEmailException,
    WeakPasswordException,
    MissingFieldException,
    InvalidShopTypeException
)
from .database_exceptions import (
    DatabaseException,
    RecordNotFoundException,
    DuplicateRecordException
)

__all__ = [
    'AppException',
    'AuthException',
    'InvalidCredentialsException',
    'UserAlreadyExistsException',
    'UnauthorizedException',
    'TokenExpiredException',
    'InvalidTokenException',
    'ValidationException',
    'InvalidEmailException',
    'WeakPasswordException',
    'MissingFieldException',
    'InvalidShopTypeException',
    'DatabaseException',
    'RecordNotFoundException',
    'DuplicateRecordException',
]
