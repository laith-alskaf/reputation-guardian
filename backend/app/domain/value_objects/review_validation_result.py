"""
Review Validation Result Value Object
Encapsulates validation results for review processing.
"""
from dataclasses import dataclass
from typing import Optional


@dataclass(frozen=True)
class ReviewValidationResult:
    """
    Immutable value object representing the result of review validation.
    
    Attributes:
        is_valid: Whether the validation passed
        error_message: Human-readable error message if validation failed
        error_type: Classification of the error for programmatic handling
                   ('missing_field', 'duplicate', 'not_found', 'invalid_data')
    """
    is_valid: bool
    error_message: Optional[str] = None
    error_type: Optional[str] = None
    
    @staticmethod
    def success() -> 'ReviewValidationResult':
        """Create a successful validation result."""
        return ReviewValidationResult(is_valid=True)
    
    @staticmethod
    def failure(error_message: str, error_type: str = 'validation_error') -> 'ReviewValidationResult':
        """Create a failed validation result."""
        return ReviewValidationResult(
            is_valid=False,
            error_message=error_message,
            error_type=error_type
        )
