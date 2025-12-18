"""
Process Telegram Use Case
Handles Telegram bot webhook updates.
"""
import logging
from typing import Dict, Any

from app.application.services.webhook.handlers.telegram_handler import TelegramHandler


class ProcessTelegramUseCase:
    """
    Use case for processing Telegram webhook updates.
    
    Orchestrates Telegram bot interactions through the TelegramHandler.
    Follows clean architecture principles with dependency injection.
    """
    
    def __init__(self, telegram_handler: TelegramHandler):
        """
        Initialize use case with required dependencies.
        
        Args:
            telegram_handler: Handler for Telegram bot interactions
        """
        self.telegram_handler = telegram_handler
    
    def execute(self, update_data: Dict[str, Any]) -> None:
        """
        Execute the Telegram webhook processing use case.
        
        Args:
            update_data: Telegram webhook update payload
        """
        logging.info("Processing Telegram webhook update")
        self.telegram_handler.process_telegram_update(update_data)
