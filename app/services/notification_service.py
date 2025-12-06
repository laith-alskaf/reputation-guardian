import firebase_admin
from firebase_admin import credentials, messaging
import json
from app.config import FIREBASE_JSON, TELEGRAM_TOKEN
import telegram
import os

def initialize_firebase():
    """
    Initialize Firebase app with credentials.
    """
    try:
        # Assuming FIREBASE_JSON is the JSON string
        cred_dict = json.loads(FIREBASE_JSON)
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred)
        print("Firebase initialized successfully")
    except Exception as e:
        print(f"Error initializing Firebase: {e}")

def send_fcm_notification(device_token, message, title="تقييم جديد"):
    """
    Send FCM notification.
    """
    try:
        msg = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=message
            ),
            token=device_token
        )
        response = messaging.send(msg)
        print(f"Notification sent: {response}")
    except Exception as e:
        print(f"Error sending notification: {e}")

def send_telegram_notification(chat_id, message):
    """
    Send Telegram notification as alternative to FCM.
    """
    if not TELEGRAM_TOKEN:
        print("Telegram token not set")
        return

    try:
        bot = telegram.Bot(token=TELEGRAM_TOKEN)
        bot.send_message(chat_id=chat_id, text=message)
        print(f"Telegram notification sent to {chat_id}")
    except Exception as e:
        print(f"Error sending Telegram notification: {e}")

if __name__ == "__main__":
    initialize_firebase()
    # Test (replace with actual token)
    # send_fcm_notification("device_token_here", "Test message")
    # send_telegram_notification("chat_id_here", "Test message")
