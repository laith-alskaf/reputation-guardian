"""
Notification Handler
Sends review notifications to shop owners via FCM or Telegram.
"""
import logging

from app.infrastructure.external import NotificationService, TelegramService
from app.application.dto.review_processing_dto import ReviewDocument


class NotificationHandler:
    """
    Handles sending notifications for new reviews.
    
    Responsibility: Send notifications through appropriate channels.
    Follows SRP - only handles notification sending logic.
    """
    
    def __init__(self, notification_service: NotificationService, telegram_service: TelegramService):
        """
        Initialize NotificationHandler with required dependencies.
        
        Args:
            notification_service: Service for FCM notifications
            telegram_service: Service for Telegram notifications
        """
        self.notification_service = notification_service
        self.telegram_service = telegram_service
    
    def send_review_notification(self, owner, review_doc: ReviewDocument) -> None:
        """
        Send notification based on the processed review document.
        
        Determines the appropriate notification channel (FCM or Telegram)
        based on owner preferences and sends formatted notification.
        
        Args:
            owner: User/Shop owner object with notification preferences
            review_doc: Processed review document
        """
        try:
            if not owner:
                logging.warning(f"No owner found for shop {review_doc.shop_id}")
                return
            
            # Check if owner has notification channels configured
            if not (owner.device_token or owner.telegram_chat_id):
                logging.info(f"No notification channels configured for shop {review_doc.shop_id}")
                return
            
            # Send via FCM if device token is available
            if owner.device_token:
                self._send_fcm_notification(owner.device_token, review_doc)
            
            # Send via Telegram if chat ID is available
            elif owner.telegram_chat_id:
                self._send_telegram_notification(owner.telegram_chat_id, review_doc)
                
        except Exception as e:
            logging.error(f"Notification failed for shop {review_doc.shop_id}: {e}")
    
    def _send_fcm_notification(self, device_token: str, review_doc: ReviewDocument) -> None:
        """
        Send simple FCM notification.
        
        Args:
            device_token: FCM device token
            review_doc: Review document
        """
        try:
            stars = '⭐' * (review_doc.source.rating or 0)
            sentiment = review_doc.analysis.get('sentiment', 'محايد')
            message = f"تقييم جديد: {stars}\n{sentiment}"
            
            self.notification_service.send_fcm_notification(device_token, message)
            logging.info(f"FCM notification sent for shop {review_doc.shop_id}")
            
        except Exception as e:
            logging.error(f"FCM notification failed: {e}")
    
    def _send_telegram_notification(self, chat_id: str, review_doc: ReviewDocument) -> None:
        """
        Send rich formatted Telegram notification.
        
        Args:
            chat_id: Telegram chat ID
            review_doc: Review document
        """
        try:
            self.telegram_service.send_review_notification(chat_id, review_doc)
            logging.info(f"Telegram notification sent for shop {review_doc.shop_id}")
            
        except Exception as e:
            logging.error(f"Telegram notification failed: {e}")
