"""User repository."""
from typing import Optional
from bson import ObjectId
import bcrypt
from app.domain.models.user import User
from app.infrastructure.repositories.base_repository import BaseRepository
from app.infrastructure.database import MongoDBManager
import logging

logger = logging.getLogger(__name__)


class UserRepository(BaseRepository[User]):
    """Repository for User entities."""
    
    def __init__(self):
        db = MongoDBManager().db
        super().__init__(db['users'])
    
    def to_entity(self, data: dict) -> User:
        """Convert database document to User entity."""
        return User.from_dict(data)
    
    def to_document(self, entity: User) -> dict:
        """Convert User entity to database document."""
        return entity.to_dict()
    
    # Custom methods
    
    def find_by_email(self, email: str) -> Optional[User]:
        """Find user by email."""
        return self.find_one({'email': email.lower().strip()})
    
    def email_exists(self, email: str) -> bool:
        """Check if email already exists."""
        return self.exists({'email': email.lower().strip()})
    
    def create_user(self, email: str, password: str, shop_name: str, shop_type: str, device_token: str = '') -> str:
        """
        Create a new user with hashed password.
        
        Returns:
            User ID as string
        """
        # Hash password
        hashed_pw = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        # Create user entity
        user = User(
            email=email.lower().strip(),
            password_hash=hashed_pw,
            shop_name=shop_name.strip(),
            shop_type=shop_type,
            device_token=(device_token or "").strip()
        )
        
        user_id = self.insert(user)
        logger.info(f"Created user with email: {email}")
        return str(user_id)
    
    def verify_password(self, stored_password_hash: str, provided_password: str) -> bool:
        """Verify password against hash."""
        try:
            return bcrypt.checkpw(
                provided_password.encode('utf-8'),
                stored_password_hash.encode('utf-8')
            )
        except Exception as e:
            logger.error(f"Password verification error: {e}")
            return False
    
    def update_user(self, user_id: ObjectId, update_data: dict) -> bool:
        """
        Update user with allowed fields only.
        
        Args:
            user_id: User ID
            update_data: Dictionary with fields to update
            
        Returns:
            True if updated, False otherwise
        """
        # Filter allowed fields
        allowed_fields = ['shop_name', 'shop_type', 'device_token', 'telegram_chat_id']
        filtered_data = {k: v for k, v in update_data.items() if k in allowed_fields}
        
        if not filtered_data:
            logger.warning("No valid fields to update")
            return False
        
        # Always update updated_at
        from datetime import datetime
        filtered_data['updated_at'] = datetime.utcnow()
        
        return self.update(user_id, filtered_data)
