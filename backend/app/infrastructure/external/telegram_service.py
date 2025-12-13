import logging
from typing import Optional
from app.domain.services_interfaces import ITelegramService, INotificationService
from app.application.dto.review_processing_dto import ReviewDocument

class TelegramService(ITelegramService):
    """Specialized service for Telegram notifications with rich formatting."""
    
    def __init__(self, notification_service: INotificationService):
        self.notification_service = notification_service
        self.max_length = 4096  # Telegram message limit
        
    def send_review_notification(self, chat_id: str, review_doc: ReviewDocument) -> None:
        """Send formatted review notification to Telegram."""
        try:
            message = self.build_review_message(review_doc)
            self.notification_service.send_telegram_notification(chat_id, message)
            logging.info(f"Review notification sent to Telegram chat {chat_id}")
        except Exception as e:
            logging.error(f"Failed to send Telegram review notification: {e}")
            raise
    
    def build_review_message(self, review_doc: ReviewDocument) -> str:
        """Build complete formatted message from review data."""
        parts = [
            self._format_header(review_doc),
            self._format_content(review_doc),
            self._format_customer_info(review_doc),
            self._format_insights(review_doc),
            self._format_warnings(review_doc),
            self._format_footer()
        ]
        
        message = "\n".join(filter(None, parts))
        return self._ensure_length_limit(message)
    
    def _format_header(self, review_doc: ReviewDocument) -> str:
        """Format header with stars, sentiment, and quality score."""
        rating = review_doc.source.rating or 0
        stars = '⭐' * rating
        
        sentiment = review_doc.analysis.get('sentiment', 'محايد')
        sentiment_emoji = self._get_sentiment_emoji(sentiment)
        
        quality_score = review_doc.analysis.get('quality', {}).get('quality_score', 0)
        quality_percentage = round(quality_score * 100)
        
        header = f"🔔 *تقييم جديد وصل الآن!*\n\n"
        header += f"{stars} ({rating} نجوم)\n"
        header += f"{sentiment_emoji} {sentiment} | 📊 جودة: {quality_percentage}%\n"
        
        return header
    
    def _format_content(self, review_doc: ReviewDocument) -> str:
        """Format review text and classification."""
        text = review_doc.processing.concatenated_text or ""
        truncated_text = self._truncate_text(text, 150)
        
        category = review_doc.analysis.get('category', 'عام')
        themes = review_doc.analysis.get('key_themes', [])
        
        content = f"\n📝 *نص التقييم:*\n\"{truncated_text}\"\n"
        
        # Classification with themes
        content += f"\n🏷️ *التصنيف:* {category}"
        if themes:
            themes_text = " | ".join(themes[:2])
            content += f" | {themes_text}"
        
        return content
    
    def _format_customer_info(self, review_doc: ReviewDocument) -> Optional[str]:
        """Format customer contact information."""
        email = review_doc.email
        phone = review_doc.source.fields.get('phone') if review_doc.source.fields else None
        
        if not email and not phone:
            return None
        
        info = "\n\n👤 *معلومات العميل:*\n"
        
        if email:
            info += f"📧 {email}\n"
        
        if phone:
            info += f"📱 {phone}\n"
        
        return info.rstrip()
    
    def _format_insights(self, review_doc: ReviewDocument) -> Optional[str]:
        """Format AI insights for negative reviews."""
        sentiment = review_doc.analysis.get('sentiment')
        
        # Only show insights for negative reviews
        if sentiment != 'سلبي':
            return None
        
        insights = review_doc.generated_content.get('actionable_insights', [])
        suggested_reply = review_doc.generated_content.get('suggested_reply', '')
        
        if not insights and not suggested_reply:
            return None
        
        content = "\n"
        
        # Actionable insights
        if insights:
            content += "\n💡 *مقترحات للتحسين:*\n"
            for insight in insights[:3]:  # Max 3 insights
                content += f"• {insight}\n"
        
        # Suggested reply
        if suggested_reply:
            truncated_reply = self._truncate_text(suggested_reply, 100)
            content += f"\n📨 *رد مقترح:*\n\"{truncated_reply}\"\n"
        
        return content
    
    def _format_warnings(self, review_doc: ReviewDocument) -> Optional[str]:
        """Format quality/profanity/mismatch warnings."""
        warnings = []
        
        # Context mismatch
        if review_doc.analysis.get('context', {}).get('has_mismatch'):
            warnings.append("▫️ قد يكون التقييم عن متجر آخر")
        
        # Profanity
        if review_doc.processing.is_profane:
            warnings.append("▫️ يحتوي على ألفاظ غير لائقة")
        
        # Low quality
        if review_doc.analysis.get('quality', {}).get('is_suspicious'):
            warnings.append("▫️ جودة مشكوك فيها")
        
        if not warnings:
            return None
        
        content = "\n\n⚠️ *تنبيهات:*\n"
        content += "\n".join(warnings)
        
        return content
    
    def _format_footer(self) -> str:
        """Format action link to dashboard."""
        # TODO: Replace with actual dashboard URL
        return "\n\n🔗 عرض التفاصيل الكاملة في لوحة التحكم"
    
    def _get_sentiment_emoji(self, sentiment: str) -> str:
        """Get emoji for sentiment."""
        mapping = {
            'إيجابي': '😊',
            'سلبي': '😞',
            'محايد': '😐'
        }
        return mapping.get(sentiment, '📝')
    
    def _truncate_text(self, text: str, max_length: int) -> str:
        """Truncate text if too long."""
        if len(text) <= max_length:
            return text
        return text[:max_length] + "..."
    
    def _ensure_length_limit(self, message: str) -> str:
        """Ensure message doesn't exceed Telegram's limit."""
        if len(message) <= self.max_length:
            return message
        
        # If too long, create a summary
        logging.warning(f"Message too long ({len(message)} chars), creating summary")
        return message[:self.max_length - 50] + "\n\n... (الرسالة طويلة، راجع لوحة التحكم)"
    
    # Connection messages
    def send_connection_success(self, chat_id: str) -> None:
        """Send connection success message."""
        message = (
            "✅ *تم ربط حسابك بنجاح!*\n\n"
            "🤖 ستصلك الآن إشعارات فورية بجميع التقييمات الجديدة.\n\n"
            "💡 يمكنك إلغاء الربط في أي وقت من لوحة التحكم."
        )
        self.notification_service.send_telegram_notification(chat_id, message)
    
    def send_connection_error(self, chat_id: str) -> None:
        """Send connection error message."""
        message = (
            "❌ *عذراً، لم يتم العثور على الحساب*\n\n"
            "تأكد من استخدام الرابط الصحيح من لوحة التحكم في الموقع.\n\n"
            "🔗 قم بتسجيل الدخول واضغط على 'تفعيل التنبيهات'"
        )
        self.notification_service.send_telegram_notification(chat_id, message)
    
    def send_welcome_message(self, chat_id: str) -> None:
        """Send welcome message for new users."""
        message = (
            "👋 *مرحباً بك في بوت Reputation Guardian!*\n\n"
            "🤖 هذا البوت سيساعدك في:\n"
            "• استقبال إشعارات فورية بالتقييمات الجديدة\n"
            "• معرفة المشاعر و الجودة لكل تقييم\n"
            "• الحصول على مقترحات للتحسين\n\n"
            "🔗 لربط حسابك:\n"
            "1. سجل الدخول في لوحة التحكم\n"
            "2. اضغط على زر 'تفعيل التنبيهات'\n"
            "3. اتبع التعليمات"
        )
        self.notification_service.send_telegram_notification(chat_id, message)
