import qrcode
from io import BytesIO
import base64
from app.config import TALLY_FORM_URL
from app.services_interfaces import IQRService
import logging

class QRService(IQRService):
    def generate_qr(self, shop_id: str) -> str:
        try:
            url = f"{TALLY_FORM_URL}?shop_id={shop_id}"
            qr = qrcode.QRCode(version=1, box_size=10, border=5)
            qr.add_data(url)
            qr.make(fit=True)

            img = qr.make_image(fill_color="black", back_color="white")
            buffered = BytesIO()
            img.save(buffered, format="PNG")
            return base64.b64encode(buffered.getvalue()).decode()
        except Exception as e:
            logging.error(f"Error generating QR: {e}")
            raise

    def generate_qr_with_type(self, shop_id: str, shop_type: str = None, shop_name: str = None) -> str:
        try:
            url = f"{TALLY_FORM_URL}?shop_id={shop_id}"
            if shop_type:
                url += f"&shop_type={shop_type}"
            if shop_name:
                url += f"&shop_name={shop_name}"

            qr = qrcode.QRCode(version=1, box_size=10, border=5)
            qr.add_data(url)
            qr.make(fit=True)

            img = qr.make_image(fill_color="black", back_color="white")
            buffered = BytesIO()
            img.save(buffered, format="PNG")
            return base64.b64encode(buffered.getvalue()).decode()
        except Exception as e:
            logging.error(f"Error generating QR with type: {e}")
            raise

    def generate_qr_file(self, shop_id: str, filename: str = "qr_code.png") -> None:
        try:
            url = f"{TALLY_FORM_URL}?shop_id={shop_id}"
            qr = qrcode.QRCode(version=1, box_size=10, border=5)
            qr.add_data(url)
            qr.make(fit=True)

            img = qr.make_image(fill_color="black", back_color="white")
            img.save(filename)
            logging.info(f"QR code saved to {filename}")
        except Exception as e:
            logging.error(f"Error saving QR file: {e}")
            raise
