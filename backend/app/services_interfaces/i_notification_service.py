from abc import ABC, abstractmethod

class INotificationService(ABC):
    @abstractmethod
    def send_fcm_notification(self, device_token: str, message: str, title: str = "تقييم جديد") -> None:
        """إرسال إشعار عبر Firebase Cloud Messaging"""
        pass

    @abstractmethod
    def send_telegram_notification(self, chat_id: str, message: str) -> None:
        """إرسال إشعار عبر Telegram"""
        pass