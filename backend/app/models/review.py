from bson import ObjectId
import datetime
from datetime import timezone
from app.utils.db import connect_to_mongodb

class ReviewModel:
    def __init__(self):
        self.db = connect_to_mongodb()
        self.collection = self.db['reviews']

    def find_by_shop(self, shop_id):
        return list(self.collection.find({"shop_id": shop_id}))

    def find_existing_review(self, email, shop_id):
        return self.collection.find_one({"email": email, "shop_id": shop_id})

    def create_review(self, review_data):
        review_data['timestamp'] = datetime.datetime.now(timezone.utc)
        if 'id' not in review_data:
            review_data['id'] = str(ObjectId())
        result = self.collection.insert_one(review_data)
        return str(result.inserted_id)

    def get_recent_reviews(self, shop_id, limit=10):
        return list(self.collection.find({"shop_id": shop_id}).sort("timestamp", -1).limit(limit))
