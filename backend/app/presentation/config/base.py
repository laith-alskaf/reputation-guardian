"""Base configuration class for all environments."""
import os
from typing import List
from dotenv import load_dotenv

load_dotenv()

class BaseConfig:
    """Base configuration with common settings."""
    
    # Basic Flask Config
    SECRET_KEY = os.environ.get('SECRET_KEY')
    if not SECRET_KEY:
        raise ValueError("SECRET_KEY environment variable is required")
    
    DEBUG = False
    TESTING = False
    
    # MongoDB
    MONGO_URI = os.environ.get('MONGO_URI')
    if not MONGO_URI:
        raise ValueError("MONGO_URI environment variable is required")
    DATABASE_NAME = 'ReputationGuardian'
    
    # CORS
    @property
    def CORS_ORIGINS(self) -> List[str]:
        """Parse CORS origins from environment variable."""
        origins = os.environ.get('CORS_ORIGINS', '')
        return [origin.strip() for origin in origins.split(',') if origin.strip()]
    
    # JWT
    JWT_ACCESS_TOKEN_EXPIRES = 2592000  # 30 days in seconds
    
    # External APIs
    HF_TOKEN = os.environ.get('HF_TOKEN')
    HF_SENTIMENT_MODEL_URL = os.environ.get('HF_SENTIMENT_MODEL_URL')
    HF_TOXICITY_MODEL_URL = os.environ.get('HF_TOXICITY_MODEL_URL')
    API_URL = os.environ.get("API_URL")
    MODEL_ID = os.environ.get("MODEL_ID")
    
    # Firebase
    FIREBASE_JSON = os.environ.get('FIREBASE_JSON')
    
    # Telegram
    TELEGRAM_TOKEN = os.environ.get('TELEGRAM_TOKEN')
    
    # Business Logic
    QUALITY_GATE_THRESHOLD = float(os.environ.get('QUALITY_GATE_THRESHOLD', 0.7))
    
    # Other
    TALLY_FORM_URL = os.environ.get('TALLY_FORM_URL')
    SIGNING_SECRET = os.environ.get('SIGNING_SECRET')
    
    # Shop Types
    SHOP_TYPES = [
        "مطعم", "مقهى", "محل ملابس", "صيدلية", "سوبر ماركت",
        "متجر إلكترونيات", "مكتبة", "محل تجميل", "صالة رياضية",
        "مدرسة/روضة", "مستشفى/عيادة", "محطة وقود", "متجر أجهزة",
        "محل ألعاب", "مكتب سياحي", "محل هدايا", "مغسلة ملابس",
        "متجر هواتف", "محل أثاث", "آخر"
    ]
    
    # Logging
    LOG_LEVEL = 'INFO'
    LOG_FORMAT = '[%(asctime)s] %(levelname)s in %(module)s: %(message)s'
