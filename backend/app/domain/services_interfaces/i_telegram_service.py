from abc import ABC, abstractmethod
from app.application.dto.review_processing_dto import ReviewDocument

class ITelegramService(ABC):
    """Interface for Telegram notification service."""
    
    @abstractmethod
    def send_review_notification(self, chat_id: str, review_doc: ReviewDocument) -> None:
        """
        Send formatted review notification to Telegram.
        
        Args:
            chat_id: Telegram chat ID
            review_doc: Review document with all data
        """
        pass
    
    @abstractmethod
    def build_review_message(self, review_doc: ReviewDocument) -> str:
        """
        Build formatted message from review data.
        
        Args:
            review_doc: Review document with all data
            
        Returns:
            Formatted Telegram message with Markdown
        """
        pass
    
    @abstractmethod
    def send_connection_success(self, chat_id: str) -> None:
        """Send connection success message."""
        pass
    
    @abstractmethod
    def send_connection_error(self, chat_id: str) -> None:
        """Send connection error message."""
        pass
    
    @abstractmethod
    def send_welcome_message(self, chat_id: str) -> None:
        """Send welcome message for new users."""
        pass
