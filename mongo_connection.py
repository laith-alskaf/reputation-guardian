import pymongo
from config import MONGO_URI, DATABASE_NAME

def connect_to_mongodb():
    try:
        client = pymongo.MongoClient(MONGO_URI)
        db = client[DATABASE_NAME]
        print("Connected to MongoDB successfully")
        return db
    except Exception as e:
        print(f"Error connecting to MongoDB: {e}")
        return None

def test_mongodb():
    db = connect_to_mongodb()
    if db is None:
        return

    users = db['users']
    reviews = db['reviews']

    # Insert test data
    test_user = {"email": "test@example.com", "shop_name": "متجر تجريبي"}
    users.insert_one(test_user)
    print("Test user inserted")

    # Find and print
    found_user = users.find_one({"email": "test@example.com"})
    print(f"Found user: {found_user}")

    # Clean up (optional)
    # users.delete_one({"email": "test@example.com"})

if __name__ == "__main__":
    test_mongodb()
