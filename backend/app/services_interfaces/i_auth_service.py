# app/interfaces/i_auth_service.py
from abc import ABC, abstractmethod

class IAuthService(ABC):
    @abstractmethod
    def register(self, email: str, password: str, shop_name: str, shop_type: str, device_token: str = "") -> str:
        """تسجيل مستخدم جديد وإرجاع معرف المتجر"""
        pass

    @abstractmethod
    def login(self, email: str, password: str) -> dict:
        """تسجيل الدخول وإرجاع بيانات التوكن"""
        pass