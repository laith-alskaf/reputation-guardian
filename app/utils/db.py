import pymongo
from app.config import MONGO_URI, DATABASE_NAME

# متغير داخلي لتخزين الاتصال مرة واحدة
_client = None
_db = None

def connect_to_mongodb():
    global _client, _db
    try:
        if _db is None:  # إذا ما اتصلنا من قبل
            _client = pymongo.MongoClient(MONGO_URI)
            _db = _client[DATABASE_NAME]
            print("Connected to MongoDB successfully")
        return _db
    except Exception as e:
        print(f"Error connecting to MongoDB: {e}")
        return None