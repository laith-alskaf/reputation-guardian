"""Email value object."""
import re
from dataclasses import dataclass
from app.application.shared.exceptions import InvalidEmailException


@dataclass(frozen=True)
class Email:
    """Email value object (immutable)."""
    
    value: str
    
    def __post_init__(self):
        """Validate email on creation."""
        if not self._is_valid_email(self.value):
            raise InvalidEmailException()
    
    @staticmethod
    def _is_valid_email(email: str) -> bool:
        """Validate email format."""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, email))
    
    def __str__(self) -> str:
        return self.value
