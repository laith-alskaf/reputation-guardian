"""Base repository with common database operations."""
from typing import Generic, TypeVar, Optional, List, Dict, Any
from abc import ABC, abstractmethod
from bson import ObjectId
from pymongo.collection import Collection
from pymongo.results import InsertOneResult, UpdateResult, DeleteResult
import logging

logger = logging.getLogger(__name__)

T = TypeVar('T')


class BaseRepository(ABC, Generic[T]):
    """Base repository with CRUD operations."""
    
    def __init__(self, collection: Collection):
        self.collection = collection
    
    @abstractmethod
    def to_entity(self, data: dict) -> T:
        """Convert database document to domain entity."""
        pass
    
    @abstractmethod
    def to_document(self, entity: T) -> dict:
        """Convert domain entity to database document."""
        pass
    
    def find_by_id(self, entity_id: ObjectId) -> Optional[T]:
        """Find entity by ID."""
        data = self.collection.find_one({'_id': entity_id})
        return self.to_entity(data) if data else None
    
    def find_one(self, filter_dict: dict) -> Optional[T]:
        """Find one entity by filter."""
        data = self.collection.find_one(filter_dict)
        return self.to_entity(data) if data else None
    
    def find_all(self, filter_dict: dict = None, skip: int = 0, limit: int = 0, sort: List[tuple] = None) -> List[T]:
        """Find all entities matching filter."""
        cursor = self.collection.find(filter_dict or {})
        
        if sort:
            cursor = cursor.sort(sort)
        if skip > 0:
            cursor = cursor.skip(skip)
        if limit > 0:
            cursor = cursor.limit(limit)
        
        return [self.to_entity(data) for data in cursor]
    
    def insert(self, entity: T) -> ObjectId:
        """Insert new entity."""
        document = self.to_document(entity)
        # Remove _id if it's None
        if document.get('_id') is None:
            document.pop('_id', None)
        
        result: InsertOneResult = self.collection.insert_one(document)
        logger.info(f"Inserted document with ID: {result.inserted_id}")
        return result.inserted_id
    
    def update(self, entity_id: ObjectId, update_data: dict) -> bool:
        """Update entity by ID."""
        result: UpdateResult = self.collection.update_one(
            {'_id': entity_id},
            {'$set': update_data}
        )
        logger.info(f"Updated document {entity_id}: {result.modified_count} modified")
        return result.modified_count > 0
    
    def delete(self, entity_id: ObjectId) -> bool:
        """Delete entity by ID."""
        result: DeleteResult = self.collection.delete_one({'_id': entity_id})
        logger.info(f"Deleted document {entity_id}: {result.deleted_count} deleted")
        return result.deleted_count > 0
    
    def count(self, filter_dict: dict = None) -> int:
        """Count entities matching filter."""
        return self.collection.count_documents(filter_dict or {})
    
    def exists(self, filter_dict: dict) -> bool:
        """Check if entity exists."""
        return self.collection.count_documents(filter_dict, limit=1) > 0
