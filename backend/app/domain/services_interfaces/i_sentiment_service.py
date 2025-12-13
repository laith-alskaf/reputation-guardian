from abc import ABC, abstractmethod

class ISentimentService(ABC):
    @abstractmethod
    def clean_text(self, text: str) -> str:
        """تنظيف النص العربي"""
        pass

    @abstractmethod
    def analyze_sentiment(self, text: str) -> str:
        """تحليل المشاعر باستخدام نموذج BERT"""
        pass

    @abstractmethod
    def analyze_toxicity(self, text: str) -> str:
        """تحليل السمية باستخدام نموذج Toxic-BERT"""
        pass

    @abstractmethod
    def classify_review(self, sentiment: str, toxicity: str) -> str:
        """تصنيف التقييم بناءً على المشاعر والسمية"""
        pass

    @abstractmethod
    def detect_review_quality(self, text: str, enjoy_most: str, improve_product: str, additional_feedback: str) -> dict:
        """كشف جودة التقييم وتحديد إذا كان مشبوه أو سبام"""
        pass