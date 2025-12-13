import pymongo
import logging
from app.presentation.config import get_config

logger = logging.getLogger(__name__)

# Get configuration
config = get_config()

# متغير داخلي لتخزين الاتصال مرة واحدة
_client = None
_db = None

def connect_to_mongodb():
    global _client, _db
    try:
        if _db is None:  # إذا ما اتصلنا من قبل
            _client = pymongo.MongoClient(config.MONGO_URI)
            _db = _client[config.DATABASE_NAME]
            logger.info("Connected to MongoDB successfully")
        return _db
    except Exception as e:
        logger.error(f"Error connecting to MongoDB: {e}")
        return None