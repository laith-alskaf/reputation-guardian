from dataclasses import dataclass
from typing import Optional

@dataclass
class RegisterDTO:
    email: str
    password: str
    shop_name: str
    shop_type: str
    device_token: Optional[str] = None

    @staticmethod
    def from_dict(data: dict):
        return RegisterDTO(
            email=data.get("email", "").strip().lower(),
            password=data.get("password", ""),
            shop_name=data.get("shop_name", "").strip(),
            shop_type=data.get("shop_type", "").strip(),
            device_token=data.get("device_token")
        )


@dataclass
class LoginDTO:
    email: str
    password: str

    @staticmethod
    def from_dict(data: dict):
        return LoginDTO(
            email=data.get("email", "").strip().lower(),
            password=data.get("password", "")
        )