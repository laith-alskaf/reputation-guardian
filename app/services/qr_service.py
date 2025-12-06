import qrcode
from io import BytesIO
import base64
from app.config import TALLY_FORM_URL

def generate_qr(shop_id):
    """
    Generate a QR code for the Tally form with shop_id parameter.
    Shop type will be determined from the database when QR is requested.
    """
    url = f"{TALLY_FORM_URL}?shop_id={shop_id}"

    qr = qrcode.QRCode(
        version=1,
        box_size=10,
        border=5
    )
    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")

    # Save to BytesIO and encode to base64
    buffered = BytesIO()
    img.save(buffered, format="PNG")
    qr_base64 = base64.b64encode(buffered.getvalue()).decode()

    return qr_base64

def generate_qr_with_type(shop_id, shop_type=None):
    """
    Generate QR with shop type included in URL for better DeepSeek analysis.
    """
    url = f"{TALLY_FORM_URL}?shop_id={shop_id}"
    if shop_type:
        url += f"&shop_type={shop_type}"

    qr = qrcode.QRCode(
        version=1,
        box_size=10,
        border=5
    )
    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")

    buffered = BytesIO()
    img.save(buffered, format="PNG")
    qr_base64 = base64.b64encode(buffered.getvalue()).decode()

    return qr_base64

def generate_qr_file(shop_id, filename="qr_code.png"):
    """
    Generate QR and save to file.
    """
    qr = qrcode.QRCode(
        version=1,
        box_size=10,
        border=5
    )
    url = f"{TALLY_FORM_URL}?shop_id={shop_id}"
    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    img.save(filename)
    print(f"QR code saved to {filename}")

if __name__ == "__main__":
    # Test
    qr_data = generate_qr("example_id")
    print("QR code generated (base64):", qr_data[:50] + "...")  # Print first 50 chars

    generate_qr_file("example_id")
