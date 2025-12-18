import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../enums/review_status_enum.dart';

/// Helper class for review status operations
class ReviewStatusHelper {
  const ReviewStatusHelper._();

  /// Get icon for review status
  static IconData getStatusIcon(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.processed:
        return Icons.check_circle;
      case ReviewStatus.rejectedLowQuality:
        return Icons.block;
      case ReviewStatus.rejectedIrrelevant:
        return Icons.cancel;
      case ReviewStatus.processing:
        return Icons.hourglass_empty;
    }
  }

  /// Get color for review status
  static Color getStatusColor(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.processed:
        return AppColors.success;
      case ReviewStatus.rejectedLowQuality:
        return AppColors.error;
      case ReviewStatus.rejectedIrrelevant:
        return AppColors.warning;
      case ReviewStatus.processing:
        return AppColors.info;
    }
  }

  /// Get background color for status badge
  static Color getStatusBackgroundColor(ReviewStatus status) {
    return getStatusColor(status).withOpacity(0.1);
  }

  /// Get border color for status badge
  static Color getStatusBorderColor(ReviewStatus status) {
    return getStatusColor(status).withOpacity(0.3);
  }

  /// Get status badge gradient
  static List<Color> getStatusGradient(ReviewStatus status) {
    final baseColor = getStatusColor(status);
    return [baseColor.withOpacity(0.15), baseColor.withOpacity(0.05)];
  }

  /// Get rejection reason in Arabic
  /// This handles both predefined and custom rejection reasons
  static String getRejectionReasonArabic(String? reason) {
    if (reason == null || reason.isEmpty) {
      return 'غير محدد';
    }

    // Check if it's already in Arabic (contains Arabic characters)
    if (_containsArabic(reason)) {
      return reason;
    }

    // Otherwise, try to map common English reasons
    switch (reason.toLowerCase()) {
      case 'low_quality':
      case 'low quality':
        return 'جودة منخفضة';
      case 'irrelevant':
      case 'context_mismatch':
        return 'غير ذي صلة بالمتجر';
      case 'spam':
        return 'محتوى عشوائي';
      case 'profane':
      case 'inappropriate':
        return 'محتوى غير لائق';
      default:
        return reason; // Return as-is if unknown
    }
  }

  /// Check if string contains Arabic characters
  static bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Get detailed status description
  static String getStatusDescription(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.processed:
        return 'تم قبول ومعالجة هذا التقييم بنجاح';
      case ReviewStatus.rejectedLowQuality:
        return 'تم رفض هذا التقييم بسبب الجودة المنخفضة';
      case ReviewStatus.rejectedIrrelevant:
        return 'تم رفض هذا التقييم لأنه غير ذي صلة بالمتجر';
      case ReviewStatus.processing:
        return 'جاري معالجة وتحليل هذا التقييم';
    }
  }

  /// Check if status can be displayed to user
  static bool isDisplayable(ReviewStatus status) {
    // All statuses are displayable but in different tabs
    return true;
  }

  /// Get tab name for status
  static String getTabName(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.processed:
        return 'المقبولة';
      case ReviewStatus.rejectedLowQuality:
        return 'مرفوضة - جودة';
      case ReviewStatus.rejectedIrrelevant:
        return 'مرفوضة - غير متعلقة';
      case ReviewStatus.processing:
        return 'قيد المعالجة';
    }
  }

  /// Get status emoji
  static String getStatusEmoji(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.processed:
        return '✅';
      case ReviewStatus.rejectedLowQuality:
        return '❌';
      case ReviewStatus.rejectedIrrelevant:
        return '⚠️';
      case ReviewStatus.processing:
        return '⏳';
    }
  }

  /// Check if review needs attention
  static bool needsAttention(ReviewStatus status) {
    return status.isRejected || status.isProcessing;
  }

  /// Get priority score for sorting (higher = more important)
  static int getPriority(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.processing:
        return 30;
      case ReviewStatus.processed:
        return 20;
      case ReviewStatus.rejectedLowQuality:
        return 10;
      case ReviewStatus.rejectedIrrelevant:
        return 5;
    }
  }
}
