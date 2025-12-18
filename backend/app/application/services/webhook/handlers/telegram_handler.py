"""
Telegram Handler
Processes Telegram webhook updates and bot commands.
"""
import logging
from typing import Dict, Any
from bson import ObjectId

from app.infrastructure.repositories import UserRepository
from app.infrastructure.external import TelegramService


class TelegramHandler:
    """
    Handles Telegram bot webhook updates.
    
    Responsibility: Process Telegram bot commands and interactions.
    Follows SRP - only handles Telegram webhook logic.
    """
    
    def __init__(self, user_repository: UserRepository, telegram_service: TelegramService):
        """
        Initialize TelegramHandler with required dependencies.
        
        Args:
            user_repository: Repository for user data access
            telegram_service: Service for Telegram API interactions
        """
        self.user_repository = user_repository
        self.telegram_service = telegram_service
    
    def process_telegram_update(self, update_data: Dict[str, Any]) -> None:
        """
        Process Telegram webhook updates.
        
        Expected payload structure:
        {
            "message": {
                "chat": {"id": 12345},
                "text": "/start <user_id_encoded>"
            }
        }
        
        Args:
            update_data: Telegram update payload
        """
        try:
            chat_id = update_data.get('message', {}).get('chat', {}).get('id')
            text = update_data.get('message', {}).get('text', '')
            
            if not chat_id:
                logging.warning("No chat_id in telegram webhook")
                return
            
            # Route to appropriate handler based on command
            if text.startswith('/start'):
                self._handle_start_command(chat_id, text)
            else:
                self._handle_default_message(chat_id)
                
        except Exception as e:
            logging.error(f"Error processing telegram webhook: {e}")
    
    def _handle_start_command(self, chat_id: int, text: str) -> None:
        """
        Handle /start command with user ID linking.
        
        Args:
            chat_id: Telegram chat ID
            text: Command text (e.g., "/start <user_id>")
        """
        try:
            parts = text.split()
            
            if len(parts) > 1:
                # Extract user ID from start parameter
                user_id_payload = parts[1]
                
                # Update user with Telegram chat ID
                self.user_repository.update_user(
                    ObjectId(user_id_payload),
                    {"telegram_chat_id": str(chat_id)}
                )
                
                # Send connection success message
                self.telegram_service.send_connection_success(chat_id)
                logging.info(f"Telegram linked successfully for user {user_id_payload}")
                
            else:
                # No user ID provided
                self.telegram_service.send_connection_error(chat_id)
                logging.warning(f"Start command without user ID from chat {chat_id}")
                
        except Exception as e:
            logging.error(f"Failed to handle start command: {e}")
            self.telegram_service.send_connection_error(chat_id)
    
    def _handle_default_message(self, chat_id: int) -> None:
        """
        Handle default/unknown messages.
        
        Args:
            chat_id: Telegram chat ID
        """
        try:
            self.telegram_service.send_welcome_message(chat_id)
        except Exception as e:
            logging.error(f"Failed to send welcome message: {e}")
