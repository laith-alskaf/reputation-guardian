from dataclasses import dataclass
from typing import Optional

@dataclass
class ReviewDTO:
    email: str
    phone: Optional[str]
    shop_id: str
    text: str
    stars: int
    enjoy_most: Optional[str] = None
    improve_product: Optional[str] = None
    additional_feedback: Optional[str] = None

    @staticmethod
    def from_dict(data: dict):
        fields = data.get("data", {}).get("fields", [])
        field_dict = {field["label"]: field.get("value") for field in fields}
        return ReviewDTO(
            email=str(field_dict.get("email") or "").strip().lower(),
            phone=str(field_dict.get("phone") or "").strip(),
            shop_id=str(field_dict.get("shop_id") or "").strip(),
            text=str(field_dict.get("enjoy_most") or "").strip(),
            stars=int(field_dict.get("stars") or 0),
            enjoy_most=str(field_dict.get("enjoy_most") or "").strip(),
            improve_product=str(field_dict.get("improve_product") or "").strip(),
            additional_feedback=str(field_dict.get("additional_feedback") or "").strip()
        )
