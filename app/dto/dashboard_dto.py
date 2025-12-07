from dataclasses import dataclass

@dataclass
class DashboardDTO:
    shop_id: str

    @staticmethod
    def from_request(request):
        return DashboardDTO(
            shop_id=request.shop_id  # يجي من الـ middleware بعد التحقق من التوكن
        )