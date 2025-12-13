"""Application factory."""
from flask import Flask
from flask_cors import CORS
import json
from bson import ObjectId
import datetime

from app.presentation.config import get_config
from app.presentation.config.logging_config import setup_logging
from app.presentation.middlewares import register_error_handlers
from app.infrastructure.database import MongoDBManager
from app.infrastructure.external import NotificationService
from app.domain.services_interfaces import INotificationService


class JSONEncoder(json.JSONEncoder):
    """Custom JSON encoder to handle ObjectId and datetime."""
    def default(self, obj):
        if isinstance(obj, ObjectId):
            return str(obj)
        if isinstance(obj, datetime.datetime):
            return obj.isoformat()
        return super().default(obj)


notification_service: INotificationService = None


def create_app(config_name: str = None):
    """
    Application factory.
    
    Args:
        config_name: Configuration name (development, production, testing)
    
    Returns:
        Flask application instance
    """
    global notification_service
    
    app = Flask(__name__)
    
    # Load configuration
    config = get_config(config_name)
    app.config.from_object(config)
    app.json_encoder = JSONEncoder
    
    # Setup logging
    setup_logging(app)
    app.logger.info(f"Starting application with {config.__class__.__name__}")
    
    # Initialize MongoDB FIRST (before importing controllers)
    mongo_manager = MongoDBManager()
    mongo_manager.initialize(
        mongo_uri=config.MONGO_URI,
        database_name=config.DATABASE_NAME
    )
    
    # Setup CORS - Fix: get value from property
    cors_origins = ["*"] if app.debug else ["http://localhost:3000"]
    CORS(app, origins=cors_origins)
    
    # Import blueprints AFTER MongoDB initialization
    from app.presentation.api.routes import auth_bp, qr_bp, dashboard_bp, webhook_bp
    
    # Register blueprints
    app.register_blueprint(auth_bp)
    app.register_blueprint(qr_bp)
    app.register_blueprint(dashboard_bp)
    app.register_blueprint(webhook_bp)
    
    # Register error handlers
    register_error_handlers(app)
    
    # Initialize Firebase (optional)
    try:
        notification_service = NotificationService()
        app.logger.info("Notification service initialized successfully")
    except Exception as e:
        app.logger.warning(f"Firebase initialization failed: {e}")
    
    # Health check endpoint
    @app.route('/health')
    def health_check():
        return {'status': 'healthy', 'message': 'Application is running'}, 200
    
    app.logger.info("Application initialized successfully")
    
    return app

