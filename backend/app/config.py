import os
import logging
from dotenv import load_dotenv

load_dotenv()

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# MongoDB
MONGO_URI = os.environ.get('MONGO_URI')
DATABASE_NAME = 'ReputationGuardian'
API_URL = os.environ.get("API_URL")
MODEL_ID = os.environ.get("MODEL_ID")
# Hugging Face
HF_TOKEN = os.environ.get('HF_TOKEN')
HF_SENTIMENT_MODEL_URL = os.environ.get('HF_SENTIMENT_MODEL_URL')
HF_TOXICITY_MODEL_URL = os.environ.get('HF_TOXICITY_MODEL_URL')

# JWT
SECRET_KEY = os.environ.get('SECRET_KEY')

# Firebase (load JSON content or path)
FIREBASE_JSON = os.environ.get('FIREBASE_JSON')

# Telegram
TELEGRAM_TOKEN = os.environ.get('TELEGRAM_TOKEN')

# Shop Types
SHOP_TYPES = [
    "مطعم", "مقهى", "محل ملابس", "صيدلية", "سوبر ماركت",
    "متجر إلكترونيات", "مكتبة", "محل تجميل", "صالة رياضية",
    "مدرسة/روضة", "مستشفى/عيادة", "محطة وقود", "متجر أجهزة",
    "محل ألعاب", "مكتب سياحي", "محل هدايا", "مغسلة ملابس",
    "متجر هواتف", "محل أثاث", "آخر"
]

# Other
TALLY_FORM_URL = os.environ.get('TALLY_FORM_URL')
