from abc import ABC, abstractmethod
from app.dto.review_dto import ReviewDTO

class IWebhookService(ABC):
    @abstractmethod
    def process_review(self, dto: ReviewDTO) -> dict:
        """معالجة التقييم وإرجاع البيانات اللازمة للتخزين والرد"""
        pass