from abc import ABC, abstractmethod

class IDashboardService(ABC):
    @abstractmethod
    def get_dashboard_data(self, shop_id: str, email: str, shop_type: str) -> dict:
        """إرجاع بيانات لوحة التحكم لمتجر معين"""
        pass