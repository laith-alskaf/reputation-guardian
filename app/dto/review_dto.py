from dataclasses import dataclass
from typing import Optional

@dataclass
class ReviewDTO:
    email: str
    shop_id: str
    text: str
    stars: int
    enjoy_most: Optional[str] = None
    improve_product: Optional[str] = None
    additional_feedback: Optional[str] = None

    @staticmethod
    def from_dict(data: dict):
        fields = data.get("fields", {})
        return ReviewDTO(
            email=fields.get("email", "").strip().lower(),
            shop_id=fields.get("shop_id", "").strip(),
            text=fields.get("text", "").strip(),
            stars=int(fields.get("stars", 0)) if fields.get("stars") else 0,
            enjoy_most=fields.get("enjoy_most", "").strip(),
            improve_product=fields.get("improve_product", "").strip(),
            additional_feedback=fields.get("additional_feedback", "").strip()
        )