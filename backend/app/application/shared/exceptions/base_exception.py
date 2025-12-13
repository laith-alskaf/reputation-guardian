"""Base exception classes."""

class AppException(Exception):
    """Base application exception."""
    
    def __init__(self, message: str, status_code: int = 500):
        super().__init__(message)
        self.message = message
        self.status_code = status_code
    
    def to_dict(self):
        """Convert exception to dictionary."""
        return {
            'error': self.__class__.__name__,
            'message': self.message
        }
