from flask import Flask, jsonify
from flask_cors import CORS
from app.config import SECRET_KEY
from app.controllers.auth_controller import auth_bp
from app.controllers.qr_controller import qr_bp
from app.controllers.dashboard_controller import dashboard_bp
from app.controllers.webhook_controller import webhook_bp
from app.services.notification_service import initialize_firebase
import logging
import json
from bson import ObjectId
import datetime

class JSONEncoder(json.JSONEncoder):
    """Custom JSON encoder to handle ObjectId and datetime"""
    def default(self, obj):
        if isinstance(obj, ObjectId):
            return str(obj)
        if isinstance(obj, datetime.datetime):
            return obj.isoformat()
        return super().default(obj)

def create_app():
    app = Flask(__name__)
    app.json_encoder = JSONEncoder

    # Enable CORS
    CORS(app, origins=["http://localhost:3000", "http://localhost:5000", "https://your-frontend-domain.com"])

    # Register Blueprints
    app.register_blueprint(auth_bp)
    app.register_blueprint(qr_bp)
    app.register_blueprint(dashboard_bp)
    app.register_blueprint(webhook_bp)

    # Initialize Firebase
    try:
        initialize_firebase()
    except Exception as e:
        logging.warning(f"Firebase initialization failed: {e}")

    @app.route('/')
    def health():
        return jsonify({"status": "حارس السمعة يعمل بكفاءة 🛡️", "version": "2.0"}), 200

    return app
