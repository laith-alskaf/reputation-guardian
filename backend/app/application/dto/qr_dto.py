from dataclasses import dataclass

@dataclass
class QRDTO:
    shop_id: str
    shop_type: str

    @staticmethod
    def from_request(request):
        return QRDTO(
            shop_id=request.shop_id,
            shop_type=request.shop_type
        )