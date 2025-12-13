"""MongoDB connection manager."""
import logging
from typing import Optional
from pymongo import MongoClient
from pymongo.database import Database

logger = logging.getLogger(__name__)


class MongoDBManager:
    """MongoDB connection manager (Singleton)."""
    
    _instance: Optional['MongoDBManager'] = None
    _client: Optional[MongoClient] = None
    _db: Optional[Database] = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def initialize(self, mongo_uri: str, database_name: str):
        """Initialize MongoDB connection."""
        try:
            self._client = MongoClient(mongo_uri)
            self._db = self._client[database_name]
            
            # Test connection
            self._client.admin.command('ping')
            logger.info(f"Connected to MongoDB: {database_name}")
            
        except Exception as e:
            logger.error(f"Failed to connect to MongoDB: {e}")
            raise
    
    @property
    def db(self) -> Database:
        """Get database instance."""
        if self._db is None:
            raise RuntimeError("Database not initialized. Call initialize() first.")
        return self._db
    
    @property
    def client(self) -> MongoClient:
        """Get MongoDB client."""
        if self._client is None:
            raise RuntimeError("Database not initialized. Call initialize() first.")
        return self._client
    
    def close(self):
        """Close MongoDB connection."""
        if self._client:
            self._client.close()
            logger.info("MongoDB connection closed")
            self._client = None
            self._db = None
