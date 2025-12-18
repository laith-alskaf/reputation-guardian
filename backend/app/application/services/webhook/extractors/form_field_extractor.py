"""
Form Field Extractor
Responsible for extracting and structuring form fields from webhook payloads.
"""
import logging
from typing import Dict, Any, List


class FormFieldExtractor:
    """
    Extracts key information from webhook form fields.
    
    Responsibility: Parse webhook payload and extract structured data.
    Follows SRP - only handles data extraction logic.
    """
    
    def extract(self, fields: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Extracts key information from the form 'fields' array.
        
        Args:
            fields: List of field dictionaries from webhook payload
            
        Returns:
            Dictionary containing extracted and structured data with keys:
            - rating: int
            - source_fields: dict
            - shop_id: str or None
            - respondent_email: str or None
            - respondent_phone: str or None
            - shop_type: str (default: "عام")
            - shop_name: str or None
            
        Raises:
            ValueError: If fields is empty or invalid
        """
        if not fields:
            raise ValueError("Fields array is empty")
            
        extracted_data = {
            "rating": 0,
            "source_fields": {},
            "shop_id": None,
            "respondent_email": None,
            "respondent_phone": None,
            "shop_type": "عام",
            "shop_name": None
        }
        
        for field in fields:
            label = field.get('label')
            value = field.get('value')
            
            # Store all fields in source_fields
            if label:
                extracted_data["source_fields"][label] = value
            
            # Extract specific fields
            if label == 'shop_id':
                extracted_data["shop_id"] = value
            elif label == 'email':
                extracted_data["respondent_email"] = value
            elif label == 'phone':
                extracted_data["respondent_phone"] = value
            elif label == 'shop_type':
                extracted_data["shop_type"] = value or "عام"
            elif label == 'shop_name':
                extracted_data["shop_name"] = value
            elif field.get('type') == 'RATING' or label == 'stars':
                extracted_data["rating"] = self._parse_rating(value)
        
        return extracted_data
    
    def _parse_rating(self, value: Any) -> int:
        """
        Safely parse rating value to integer.
        
        Args:
            value: Rating value from form field
            
        Returns:
            Parsed rating as integer, or 0 if parsing fails
        """
        try:
            return int(value)
        except (ValueError, TypeError):
            logging.warning(f"Could not parse rating value: {value}")
            return 0
