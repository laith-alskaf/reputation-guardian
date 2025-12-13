"""Global error handler middleware."""
import logging
from flask import jsonify
from werkzeug.exceptions import HTTPException
from app.application.shared.exceptions import AppException

logger = logging.getLogger(__name__)

def register_error_handlers(app):
    """Register global error handlers."""
    
    @app.errorhandler(AppException)
    def handle_app_exception(error: AppException):
        """Handle custom application exceptions."""
        logger.warning(
            f"{error.__class__.__name__}: {error.message}",
            exc_info=True
        )
        response = {
            'success': False,
            'message': error.message,
            'error': error.__class__.__name__
        }
        return jsonify(response), error.status_code
    
    @app.errorhandler(HTTPException)
    def handle_http_exception(error: HTTPException):
        """Handle HTTP exceptions."""
        logger.warning(f"HTTPException: {error.description}")
        response = {
            'success': False,
            'message': error.description,
            'error': error.name
        }
        return jsonify(response), error.code
    
    @app.errorhandler(Exception)
    def handle_generic_exception(error: Exception):
        """Handle unexpected exceptions."""
        logger.error(
            f"Unhandled exception: {str(error)}",
            exc_info=True
        )
        response = {
            'success': False,
            'message': 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً',
            'error': 'InternalServerError'
        }
        return jsonify(response), 500
    
    @app.errorhandler(404)
    def handle_not_found(error):
        """Handle 404 errors."""
        response = {
            'success': False,
            'message': 'الصفحة المطلوبة غير موجودة',
            'error': 'NotFound'
        }
        return jsonify(response), 404
    
    @app.errorhandler(405)
    def handle_method_not_allowed(error):
        """Handle 405 errors."""
        response = {
            'success': False,
            'message': 'الطريقة المستخدمة غير مسموح بها',
            'error': 'MethodNotAllowed'
        }
        return jsonify(response), 405
    
    logger.info("Error handlers registered successfully")
