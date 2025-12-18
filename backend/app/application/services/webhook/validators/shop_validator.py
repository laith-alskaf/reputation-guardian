"""
Shop Validator
Validates shop existence and retrieves owner data.
"""
import logging
from typing import Tuple, Optional
from bson import ObjectId

from app.infrastructure.repositories import UserRepository
from app.domain.value_objects.review_validation_result import ReviewValidationResult


class ShopValidator:
    """
    Validates shop-related data.
    
    Responsibility: Ensure shop exists and retrieve owner information.
    Follows SRP - only handles shop validation logic.
    """
    
    def __init__(self, user_repository: UserRepository):
        """
        Initialize ShopValidator with required dependencies.
        
        Args:
            user_repository: Repository for user/shop data access
        """
        self.user_repository = user_repository
    
    def validate_and_get_shop(self, shop_id: str) -> Tuple[ReviewValidationResult, Optional[any]]:
        """
        Validate shop ID and retrieve owner data.
        
        Args:
            shop_id: Shop identifier from form data
            
        Returns:
            Tuple of (validation_result, owner_object)
            - validation_result: ReviewValidationResult indicating success/failure
            - owner_object: User/Shop owner object if found, None otherwise
        """
        if not shop_id:
            return (
                ReviewValidationResult.failure(
                    "`shop_id` is missing from the form fields.",
                    error_type='missing_field'
                ),
                None
            )
        
        try:
            # Convert to ObjectId and find owner
            owner = self.user_repository.find_by_id(ObjectId(shop_id))
            
            if not owner:
                return (
                    ReviewValidationResult.failure(
                        f"Shop with ID '{shop_id}' not found.",
                        error_type='not_found'
                    ),
                    None
                )
            
            logging.info(f"Shop {shop_id} validated successfully")
            return (ReviewValidationResult.success(), owner)
            
        except Exception as e:
            logging.error(f"Error validating shop {shop_id}: {e}")
            return (
                ReviewValidationResult.failure(
                    f"Error validating shop: {str(e)}",
                    error_type='validation_error'
                ),
                None
            )
