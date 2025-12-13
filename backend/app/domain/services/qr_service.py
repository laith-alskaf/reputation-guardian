"""QR Code generation service (Domain Service)."""
import qrcode
from io import BytesIO
import base64
from app.presentation.config import TALLY_FORM_URL
import logging

logger = logging.getLogger(__name__)


class QRService:
    """QR Code generation service."""
    
    def generate_qr(self, shop_id: str) -> str:
        """Generate QR code as base64 string."""
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
            logger.error(f"Error generating QR: {e}")
            raise

    def generate_qr_with_type(self, shop_id: str, shop_type: str = None, shop_name: str = None) -> str:
        """Generate QR code with additional parameters."""
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
            logger.error(f"Error generating QR with type: {e}")
            raise

    def generate_qr_file(self, shop_id: str, filename: str = "qr_code.png") -> None:
        """Generate QR code and save to file."""
        try:
            url = f"{TALLY_FORM_URL}?shop_id={shop_id}"
            qr = qrcode.QRCode(version=1, box_size=10, border=5)
            qr.add_data(url)
            qr.make(fit=True)

            img = qr.make_image(fill_color="black", back_color="white")
            img.save(filename)
            logger.info(f"QR code saved to {filename}")
        except Exception as e:
            logger.error(f"Error saving QR file: {e}")
            raise
