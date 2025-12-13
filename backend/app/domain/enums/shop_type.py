"""Shop type enumeration."""
from enum import Enum


class ShopType(str, Enum):
    """Shop type enumeration."""
    
    RESTAURANT = "مطعم"
    CAFE = "مقهى"
    CLOTHING_STORE = "محل ملابس"
    PHARMACY = "صيدلية"
    SUPERMARKET = "سوبر ماركت"
    ELECTRONICS = "متجر إلكترونيات"
    BOOKSTORE = "مكتبة"
    BEAUTY_SALON = "محل تجميل"
    GYM = "صالة رياضية"
    SCHOOL = "مدرسة/روضة"
    HOSPITAL = "مستشفى/عيادة"
    GAS_STATION = "محطة وقود"
    APPLIANCES = "متجر أجهزة"
    TOY_STORE = "محل ألعاب"
    TRAVEL_AGENCY = "مكتب سياحي"
    GIFT_SHOP = "محل هدايا"
    LAUNDRY = "مغسلة ملابس"
    PHONE_STORE = "متجر هواتف"
    FURNITURE = "محل أثاث"
    OTHER = "آخر"
    
    @classmethod
    def values(cls):
        """Get all enum values."""
        return [item.value for item in cls]
    
    @classmethod
    def is_valid(cls, value: str) -> bool:
        """Check if value is valid."""
        return value in cls.values()
