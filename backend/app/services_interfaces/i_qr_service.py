from abc import ABC, abstractmethod

class IQRService(ABC):
    @abstractmethod
    def generate_qr(self, shop_id: str) -> str:
        """توليد رمز QR لمتجر معين وإرجاعه كـ base64"""
        pass

    @abstractmethod
    def generate_qr_with_type(self, shop_id: str, shop_type: str = None) -> str:
        """توليد رمز QR مع تضمين نوع المتجر في الرابط"""
        pass

    @abstractmethod
    def generate_qr_file(self, shop_id: str, filename: str = "qr_code.png") -> None:
        """توليد رمز QR وحفظه في ملف"""
        pass