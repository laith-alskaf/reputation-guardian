"""API routes module."""
from .auth import auth_bp
from .dashboard import dashboard_bp
from .qr import qr_bp
from .webhooks import webhook_bp

__all__ = ['auth_bp', 'dashboard_bp', 'qr_bp', 'webhook_bp']
