"""
MongoDB Schema Migration Script
================================

This script updates MongoDB collection schemas to match the application code.

Run this script to fix validation errors:
1. Users collection: password -> password_hash
2. Reviews collection: id -> _id, add nested structure support

Usage:
    python migrate_mongodb_schema.py
"""

from pymongo import MongoClient
from pymongo.errors import OperationFailure
import os
from dotenv import load_dotenv
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# MongoDB connection
MONGO_URI = os.environ.get('MONGO_URI')
DATABASE_NAME = 'ReputationGuardian'

def get_db():
    """Connect to MongoDB and return database."""
    client = MongoClient(MONGO_URI)
    db = client[DATABASE_NAME]
    logger.info(f"Connected to MongoDB: {DATABASE_NAME}")
    return db

def migrate_users_schema(db):
    """
    Update users collection schema to use password_hash instead of password.
    """
    logger.info("Migrating users collection schema...")
    
    users_schema = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["email", "password_hash", "shop_name", "shop_type"],
            "properties": {
                "_id": {
                    "bsonType": "objectId",
                    "description": "User ID"
                },
                "email": {
                    "bsonType": "string",
                    "pattern": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
                    "description": "User email address"
                },
                "password_hash": {
                    "bsonType": "string",
                    "description": "Hashed password (bcrypt)"
                },
                "shop_name": {
                    "bsonType": "string",
                    "minLength": 2,
                    "maxLength": 100,
                    "description": "Shop name"
                },
                "shop_type": {
                    "bsonType": "string",
                    "description": "Type of shop"
                },
                "device_token": {
                    "bsonType": ["string", "null"],
                    "description": "FCM device token for push notifications"
                },
                "telegram_chat_id": {
                    "bsonType": ["string", "null"],
                    "description": "Telegram chat ID for notifications"
                },
                "is_active": {
                    "bsonType": "bool",
                    "description": "Whether user account is active"
                },
                "created_at": {
                    "bsonType": "date",
                    "description": "Account creation timestamp"
                },
                "updated_at": {
                    "bsonType": "date",
                    "description": "Last update timestamp"
                }
            }
        }
    }
    
    try:
        db.command({
            "collMod": "users",
            "validator": users_schema
        })
        logger.info("✅ Users collection schema updated successfully")
    except OperationFailure as e:
        logger.error(f"❌ Failed to update users schema: {e}")
        raise

def migrate_reviews_schema(db):
    """
    Update reviews collection schema to support nested structure.
    """
    logger.info("Migrating reviews collection schema...")
    
    reviews_schema = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["shop_id", "status"],
            "properties": {
                "_id": {
                    "bsonType": "objectId",
                    "description": "Review ID"
                },
                "shop_id": {
                    "bsonType": "string",
                    "description": "Shop ID this review belongs to"
                },
                "email": {
                    "bsonType": ["string", "null"],
                    "description": "Email of the reviewer"
                },
                "status": {
                    "bsonType": "string",
                    "enum": ["pending", "processing", "processed", "rejected_low_quality", "rejected_irrelevant"],
                    "description": "Review processing status"
                },
                "stars": {
                    "bsonType": ["int", "null"],
                    "minimum": 1,
                    "maximum": 5,
                    "description": "Star rating (legacy field)"
                },
                "overall_sentiment": {
                    "bsonType": ["string", "null"],
                    "description": "Overall sentiment (legacy field)"
                },
                # Nested objects for new schema
                "source": {
                    "bsonType": ["object", "null"],
                    "description": "Source data from form submission",
                    "properties": {
                        "rating": {
                            "bsonType": ["int", "null"],
                            "minimum": 1,
                            "maximum": 5
                        },
                        "fields": {
                            "bsonType": "object",
                            "description": "Raw form field data"
                        }
                    }
                },
                "processing": {
                    "bsonType": ["object", "null"],
                    "description": "Processing information",
                    "properties": {
                        "concatenated_text": {
                            "bsonType": "string",
                            "description": "Processed review text"
                        },
                        "is_profane": {
                            "bsonType": "bool",
                            "description": "Whether review contains profanity"
                        }
                    }
                },
                "analysis": {
                    "bsonType": ["object", "null"],
                    "description": "Sentiment and quality analysis results"
                },
                "generated_content": {
                    "bsonType": ["object", "null"],
                    "description": "AI-generated content (summary, insights, reply)"
                },
                "created_at": {
                    "bsonType": ["date", "null"],
                    "description": "Review creation timestamp"
                },
                "timestamp": {
                    "bsonType": ["date", "null"],
                    "description": "Legacy timestamp field"
                }
            }
        }
    }
    
    try:
        db.command({
            "collMod": "reviews",
            "validator": reviews_schema
        })
        logger.info("✅ Reviews collection schema updated successfully")
    except OperationFailure as e:
        logger.error(f"❌ Failed to update reviews schema: {e}")
        raise

def remove_validation(db, collection_name):
    """
    Remove schema validation from a collection (useful for testing).
    
    Args:
        db: MongoDB database instance
        collection_name: Name of the collection
    """
    logger.info(f"Removing validation from {collection_name} collection...")
    try:
        db.command({
            "collMod": collection_name,
            "validator": {}
        })
        logger.info(f"✅ Validation removed from {collection_name} collection")
    except OperationFailure as e:
        logger.error(f"❌ Failed to remove validation: {e}")
        raise

def main():
    """Main migration function."""
    logger.info("=" * 60)
    logger.info("Starting MongoDB Schema Migration")
    logger.info("=" * 60)
    
    db = get_db()
    
    # Option 1: Apply proper schema validation
    try:
        migrate_users_schema(db)
        migrate_reviews_schema(db)
        logger.info("=" * 60)
        logger.info("✅ All migrations completed successfully!")
        logger.info("=" * 60)
    except Exception as e:
        logger.error(f"Migration failed: {e}")
        logger.info("\nIf you want to temporarily disable validation for testing, run:")
        logger.info("  python migrate_mongodb_schema.py --remove-validation")
        raise
    
    # Option 2: Remove validation (uncomment if needed for testing)
    # remove_validation(db, "users")
    # remove_validation(db, "reviews")

if __name__ == "__main__":
    import sys
    
    if "--remove-validation" in sys.argv:
        db = get_db()
        logger.warning("⚠️  Removing all schema validations (for testing only)")
        remove_validation(db, "users")
        remove_validation(db, "reviews")
    else:
        main()
