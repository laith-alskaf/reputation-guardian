"""Configuration module."""
import os
from .base import BaseConfig
from .development import DevelopmentConfig
from .production import ProductionConfig
from .testing import TestingConfig

config_by_name = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}

def get_config(config_name: str = None):
    """Get configuration by name or from environment."""
    if config_name is None:
        config_name = os.getenv('FLASK_ENV', 'development')
    
    return config_by_name.get(config_name, config_by_name['default'])

# Helper variables for backward compatibility
_config = get_config()
SECRET_KEY = _config.SECRET_KEY
MONGO_URI = _config.MONGO_URI
DATABASE_NAME = _config.DATABASE_NAME
HF_TOKEN = _config.HF_TOKEN
HF_SENTIMENT_MODEL_URL = _config.HF_SENTIMENT_MODEL_URL
HF_TOXICITY_MODEL_URL = _config.HF_TOXICITY_MODEL_URL
API_URL = _config.API_URL
MODEL_ID = _config.MODEL_ID
FIREBASE_JSON = _config.FIREBASE_JSON
TELEGRAM_TOKEN = _config.TELEGRAM_TOKEN
TALLY_FORM_URL = _config.TALLY_FORM_URL
QUALITY_GATE_THRESHOLD = _config.QUALITY_GATE_THRESHOLD
SHOP_TYPES = _config.SHOP_TYPES
SIGNING_SECRET = _config.SIGNING_SECRET

