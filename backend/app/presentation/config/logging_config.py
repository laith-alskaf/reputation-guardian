"""Logging configuration."""
import logging
import os
from logging.handlers import RotatingFileHandler
from pathlib import Path

def setup_logging(app):
    """Configure application logging."""
    
    # Determine log directory based on environment
    # Use /tmp for serverless (Vercel) since file system is read-only
    # Use local logs directory for development
    if os.environ.get('VERCEL') or os.environ.get('AWS_LAMBDA_FUNCTION_NAME'):
        # Serverless environment - use /tmp
        log_dir = Path('/tmp/logs')
    else:
        # Local development - use app directory
        log_dir = Path(__file__).parent.parent.parent / 'logs'
    
    # Create logs directory if it doesn't exist and filesystem is writable
    try:
        log_dir.mkdir(parents=True, exist_ok=True)
    except (OSError, PermissionError):
        # If we can't create directory, fall back to /tmp
        log_dir = Path('/tmp/logs')
        log_dir.mkdir(parents=True, exist_ok=True)
    
    # Get log level from config
    log_level = getattr(logging, app.config.get('LOG_LEVEL', 'INFO'))
    
    # Format
    formatter = logging.Formatter(app.config.get('LOG_FORMAT'))
    
    # File handler for all logs
    file_handler = RotatingFileHandler(
        log_dir / 'app.log',
        maxBytes=10485760,  # 10MB
        backupCount=10
    )
    file_handler.setFormatter(formatter)
    file_handler.setLevel(log_level)
    
    # File handler for errors only
    error_handler = RotatingFileHandler(
        log_dir / 'error.log',
        maxBytes=10485760,
        backupCount=10
    )
    error_handler.setFormatter(formatter)
    error_handler.setLevel(logging.ERROR)
    
    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    console_handler.setLevel(log_level)
    
    # Configure app logger
    app.logger.handlers.clear()
    app.logger.addHandler(file_handler)
    app.logger.addHandler(error_handler)
    app.logger.addHandler(console_handler)
    app.logger.setLevel(log_level)
    
    app.logger.info(f"Logging configured with level: {app.config.get('LOG_LEVEL')}, logs directory: {log_dir}")
