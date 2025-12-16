import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebugHelper {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString();
      final tagPrefix = tag != null ? '[$tag] ' : '';
      print('[$timestamp] $tagPrefix$message');
    }
  }

  static void logError(dynamic error, {StackTrace? stackTrace, String? tag}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString();
      final tagPrefix = tag != null ? '[$tag] ' : '';
      print('[$timestamp] ${tagPrefix}ERROR: $error');
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }
}

class SnackBarHelper {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF3B82F6),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
