import pymongo
from app.config import MONGO_URI, DATABASE_NAME

def connect_to_mongodb():
    try:
        client = pymongo.MongoClient(MONGO_URI)
        db = client[DATABASE_NAME]
        print("Connected to MongoDB successfully")
        return db
    except Exception as e:
        print(f"Error connecting to MongoDB: {e}")
        return None
