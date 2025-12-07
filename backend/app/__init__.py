from flask import Flask
from flask_cors import CORS
from app.controllers import auth_bp, qr_bp, dashboard_bp, webhook_bp
from app.services.external import NotificationService
from app.services_interfaces import INotificationService
import logging
import json
from bson import ObjectId
import datetime
import os
class JSONEncoder(json.JSONEncoder):
    """Custom JSON encoder to handle ObjectId and datetime"""
    def default(self, obj):
        if isinstance(obj, ObjectId):
            return str(obj)
        if isinstance(obj, datetime.datetime):
            return obj.isoformat()
        return super().default(obj)

notification_service: INotificationService 
def create_app():
    app = Flask(__name__)
    app.json_encoder = JSONEncoder
    # Enable CORS
    cors_origins = os.getenv("CORS_ORIGINS", "").split(",")

    CORS(app, origins=cors_origins)
    app.register_blueprint(auth_bp)
    app.register_blueprint(qr_bp)
    app.register_blueprint(dashboard_bp)
    app.register_blueprint(webhook_bp)
    try:
      notification_service: INotificationService = NotificationService()  
    except Exception as e:
        logging.warning(f"Firebase initialization failed: {e}")
    # Initialize Firebase
    # try:
    #     notification_service._initialize_firebase()
    # except Exception as e:
    #     logging.warning(f"Firebase initialization failed: {e}")

    return app
