from abc import ABC, abstractmethod

class IDeepSeekService(ABC):
    @abstractmethod
    def organize_customer_feedback(self, enjoy_most: str, improve_product: str, additional_feedback: str) -> str:
        pass

    @abstractmethod
    def generate_actionable_insights(self, text: str, improve_product: str, shop_type: str) -> str:
        pass

    @abstractmethod
    def generate_suggested_reply(self, text: str, sentiment: str, shop_type: str, customer_name: str = "العميل") -> str:
        pass

    @abstractmethod
    def determine_overall_sentiment(self, stars: int, text: str, improve_product: str, additional_feedback: str) -> str:
        pass