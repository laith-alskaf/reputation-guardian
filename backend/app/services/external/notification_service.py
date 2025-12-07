import firebase_admin
from firebase_admin import credentials, messaging
import json
import telegram
import logging
from app.config import FIREBASE_JSON, TELEGRAM_TOKEN
from app.services_interfaces import INotificationService

class NotificationService(INotificationService):
    def __init__(self):
        self._initialize_firebase()

    def _initialize_firebase(self):
        """تهيئة Firebase"""
        try:
            if not firebase_admin._apps:  # تأكد أنه لم يتم التهيئة مسبقاً
                cred_dict = json.loads(FIREBASE_JSON)
                cred = credentials.Certificate(cred_dict)
                firebase_admin.initialize_app(cred)
                logging.info("Firebase initialized successfully")
        except Exception as e:
            logging.error(f"Error initializing Firebase: {e}")

    def send_fcm_notification(self, device_token: str, message: str, title: str = "تقييم جديد") -> None:
        """إرسال إشعار عبر FCM"""
        try:
            msg = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=message
                ),
                token=device_token
            )
            response = messaging.send(msg)
            logging.info(f"Notification sent: {response}")
        except Exception as e:
            logging.error(f"Error sending FCM notification: {e}")

    def send_telegram_notification(self, chat_id: str, message: str) -> None:
        """إرسال إشعار عبر Telegram"""
        if not TELEGRAM_TOKEN:
            logging.warning("Telegram token not set")
            return

        try:
            bot = telegram.Bot(token=TELEGRAM_TOKEN)
            bot.send_message(chat_id=chat_id, text=message)
            logging.info(f"Telegram notification sent to {chat_id}")
        except Exception as e:
            logging.error(f"Error sending Telegram notification: {e}")