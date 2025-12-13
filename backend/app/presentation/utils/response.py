from flask import jsonify

class ResponseBuilder:
    """Class to unify API responses across the project."""

    @staticmethod
    def success(data=None, message="تم التنفيذ بنجاح", status_code=200):
        return jsonify({
            "status": "success",
            "message": message,
            "data": data
        }), status_code

    @staticmethod
    def error(message="حدث خطأ ما", status_code=400, errors=None):
        return jsonify({
            "status": "error",
            "message": message,
            "errors": errors
        }), status_code

    @staticmethod
    def unauthorized(message="غير مصرح بالدخول"):
        return jsonify({
            "status": "fail",
            "message": message
        }), 401

    @staticmethod
    def not_found(message="المورد غير موجود"):
        return jsonify({
            "status": "fail",
            "message": message
        }), 404