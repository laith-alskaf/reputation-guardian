from bson import ObjectId
import datetime
from datetime import timezone
from app.utils.db import connect_to_mongodb
from app.utils.time_utils import get_syria_time

class ReviewModel:
    def __init__(self):
        self.db = connect_to_mongodb()
        self.collection = self.db['reviews']

    def find_by_shop(self, shop_id):
        return list(self.collection.find({"shop_id": shop_id}))

    def find_by_status(self, shop_id: str, status: str):
        """Finds reviews for a given shop with a specific status."""
        return list(self.collection.find({"shop_id": shop_id, "status": status}))

    def find_processed_by_shop(self, shop_id: str):
        """Finds all PROCESSED reviews for a given shop."""
        return self.find_by_status(shop_id, "processed")

    def find_rejected_by_shop(self, shop_id: str):
        """Finds all REJECTED reviews for a given shop."""
        return self.find_by_status(shop_id, "rejected")

    def find_existing_review(self, email, shop_id):
        # This might need updating to check based on the new data model,
        # but for now, the logic remains based on top-level email.
        return self.collection.find_one({"email": email, "shop_id": shop_id})

    def create_review(self, review_data):
        result = self.collection.insert_one(review_data)
        return str(result.inserted_id)

    def get_recent_reviews(self, shop_id, limit=10):
        return list(self.collection.find({"shop_id": shop_id}).sort("timestamp", -1).limit(limit))
