"""Password value object."""
from dataclasses import dataclass
from app.application.shared.exceptions import WeakPasswordException


@dataclass(frozen=True)
class Password:
    """Password value object (immutable)."""
    
    value: str
    
    def __post_init__(self):
        """Validate password on creation."""
        if not self._is_strong_password(self.value):
            raise WeakPasswordException()
    
    @staticmethod
    def _is_strong_password(password: str) -> bool:
        """Validate password strength."""
        return len(password) >= 8
    
    def __str__(self) -> str:
        return self.value
