# app/services/auth_service.py
from app.domain.services_interfaces import IAuthService
from app.infrastructure.repositories import UserRepository
from app.presentation.config import SECRET_KEY
from app.application.shared.exceptions import UserAlreadyExistsException, InvalidCredentialsException
import jwt
import datetime
from app.presentation.utils.time_utils import get_syria_time
import logging

logger = logging.getLogger(__name__)


class AuthService(IAuthService):
    def __init__(self, user_repository: UserRepository = None):
        """
        Initialize AuthService with dependency injection.
        
        Args:
            user_repository: User repository (injected for testing)
        """
        self.user_repository = user_repository or UserRepository()

    def register(self, email, password, shop_name, shop_type, device_token=""):
        """Register a new user."""
        # Check if user already exists
        if self.user_repository.email_exists(email):
            raise UserAlreadyExistsException()
        
        # Create user using repository
        shop_id = self.user_repository.create_user(
            email=email,
            password=password,
            shop_name=shop_name,
            shop_type=shop_type,
            device_token=device_token
        )
        
        # Generate JWT token
        token = jwt.encode({
            "email": email,
            "shop_id": shop_id,
            "shop_type": shop_type,
            "shop_name": shop_name,
            "exp": (get_syria_time() + datetime.timedelta(days=30)).timestamp()
        }, SECRET_KEY, algorithm="HS256")
        
        logger.info(f"User registered successfully: {email}")
        return {"token": token, "shop_id": shop_id, "shop_type": shop_type, "shop_name": shop_name}

    def login(self, email, password):
        """Authenticate user and return token."""
        # Find user
        user = self.user_repository.find_by_email(email)
        if not user:
            raise InvalidCredentialsException()
        
        # Verify password
        if not self.user_repository.verify_password(user.password_hash, password):
            raise InvalidCredentialsException()
        
        # Generate token
        token = jwt.encode({
            "email": user.email,
            "shop_id": str(user.id),
            "shop_type": user.shop_type,
            "shop_name": user.shop_name,
            "exp": (get_syria_time() + datetime.timedelta(days=30)).timestamp()
        }, SECRET_KEY, algorithm="HS256")
        
        logger.info(f"User logged in: {email}")
        return {
            "token": token,
            "shop_id": str(user.id),
            "shop_type": user.shop_type,
            "shop_name": user.shop_name
        }

    def logout(self):
        """Client-side logout, no server-side action needed."""
        pass
