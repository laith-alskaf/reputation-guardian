"""
Review Validator
Validates review data integrity and checks for duplicates.
"""
import logging
from typing import Dict, Any
from bson import ObjectId

from app.infrastructure.repositories import ReviewRepository
from app.domain.value_objects.review_validation_result import ReviewValidationResult


class ReviewValidator:
    """
    Validates review-related data.
    
    Responsibility: Ensure review data is valid and not duplicated.
    Follows SRP - only handles review validation logic.
    """
    
    def __init__(self, review_repository: ReviewRepository):
        """
        Initialize ReviewValidator with required dependencies.
        
        Args:
            review_repository: Repository for review data access
        """
        self.review_repository = review_repository
    
    def validate_extracted_fields(self, extracted_fields: Dict[str, Any]) -> ReviewValidationResult:
        """
        Validate that extracted fields contain required data.
        
        Args:
            extracted_fields: Dictionary of extracted form fields
            
        Returns:
            ReviewValidationResult indicating validation status
        """
        # Check for required shop_id
        shop_id = extracted_fields.get('shop_id')
        if not shop_id:
            return ReviewValidationResult.failure(
                "`shop_id` is missing from the form fields.",
                error_type='missing_field'
            )
        
        # Additional validation can be added here
        # For example: rating range, text length, etc.
        
        return ReviewValidationResult.success()
    
    def check_duplicate_review(self, email: str, shop_id: str) -> ReviewValidationResult:
        """
        Check if a review from this email for this shop already exists.
        
        Args:
            email: Respondent email address
            shop_id: Shop identifier
            
        Returns:
            ReviewValidationResult indicating if duplicate exists
        """
        if not email:
            # If no email provided, can't check for duplicates
            # This is acceptable - some reviews might be anonymous
            return ReviewValidationResult.success()
        
        try:
            existing_review = self.review_repository.find_existing_review(email, shop_id)
            
            if existing_review:
                return ReviewValidationResult.failure(
                    f"A review from '{email}' for shop '{shop_id}' already exists.",
                    error_type='duplicate'
                )
            
            logging.info(f"No duplicate review found for {email} and shop {shop_id}")
            return ReviewValidationResult.success()
            
        except Exception as e:
            logging.error(f"Error checking duplicate review: {e}")
            return ReviewValidationResult.failure(
                f"Error checking for duplicate review: {str(e)}",
                error_type='validation_error'
            )
