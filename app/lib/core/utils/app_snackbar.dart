import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Unified Snackbar System for consistent messaging across the app
class AppSnackbar {
  /// Show a success message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.positive,
      icon: Icons.check_circle,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show an error message
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show a warning message
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_amber,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show an info message
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.info,
      icon: Icons.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Internal method to show snackbar
  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  /// Show a loading snackbar (dismissible)
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(
    BuildContext context,
    String message,
  ) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(days: 1), // Long duration, dismiss manually
      ),
    );
  }
}

/// Common Arabic error messages
class AppErrorMessages {
  static const String networkError = 'فشل الاتصال بالخادم';
  static const String unknownError = 'حدث خطأ غير متوقع';
  static const String noInternet = 'يرجى التحقق من الاتصال بالإنترنت';
  static const String sessionExpired =
      'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى';
  static const String invalidCredentials = 'بيانات الدخول غير صحيحة';
  static const String serverError = 'خطأ في الخادم، يرجى المحاولة لاحقاً';
  static const String validationError = 'يرجى التحقق من البيانات المدخلة';
  static const String notFound = 'العنصر غير موجود';
  static const String forbidden = 'ليس لديك صلاحية للوصول';
  static const String timeout = 'انتهت مهلة الطلب';
}

/// Common Arabic success messages
class AppSuccessMessages {
  static const String loginSuccess = 'تم تسجيل الدخول بنجاح';
  static const String logoutSuccess = 'تم تسجيل الخروج بنجاح';
  static const String saveSuccess = 'تم الحفظ بنجاح';
  static const String updateSuccess = 'تم التحديث بنجاح';
  static const String deleteSuccess = 'تم الحذف بنجاح';
  static const String connectSuccess = 'تم الربط بنجاح';
  static const String disconnectSuccess = 'تم فك الربط بنجاح';
  static const String generateSuccess = 'تم الإنشاء بنجاح';
}
