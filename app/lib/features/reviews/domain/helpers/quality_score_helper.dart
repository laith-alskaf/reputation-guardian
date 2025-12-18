import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../enums/quality_level_enum.dart';

/// Helper class for quality score calculations and formatting
class QualityScoreHelper {
  const QualityScoreHelper._();

  // Quality thresholds
  static const double highQualityThreshold = 0.7;
  static const double mediumQualityThreshold = 0.4;

  /// Get quality level from score
  static QualityLevel getQualityLevel(double score) {
    return QualityLevel.fromScore(score);
  }

  /// Get color based on quality score
  static Color getQualityColor(double score) {
    final level = getQualityLevel(score);
    switch (level) {
      case QualityLevel.high:
        return AppColors.success;
      case QualityLevel.medium:
        return AppColors.warning;
      case QualityLevel.low:
        return AppColors.error;
    }
  }

  /// Get gradient colors for quality score
  static List<Color> getQualityGradient(double score) {
    final baseColor = getQualityColor(score);
    return [baseColor.withOpacity(0.2), baseColor.withOpacity(0.1)];
  }

  /// Get border color for quality score
  static Color getQualityBorderColor(double score) {
    return getQualityColor(score).withOpacity(0.3);
  }

  /// Get Arabic label for quality level
  static String getQualityLabel(double score) {
    return getQualityLevel(score).arabicLabel;
  }

  /// Get percentage string from score
  static String getQualityPercentage(double score) {
    final percentage = (score * 100).clamp(0, 100).toInt();
    return '$percentage%';
  }

  /// Get detailed quality description in Arabic
  static String getQualityDescription(double score) {
    final level = getQualityLevel(score);
    switch (level) {
      case QualityLevel.high:
        return 'تقييم عالي الجودة وموثوق';
      case QualityLevel.medium:
        return 'تقييم مقبول لكن يحتاج تحسين';
      case QualityLevel.low:
        return 'تقييم ضعيف الجودة ومشكوك فيه';
    }
  }

  /// Get icon for quality level
  static IconData getQualityIcon(double score) {
    final level = getQualityLevel(score);
    switch (level) {
      case QualityLevel.high:
        return Icons.verified;
      case QualityLevel.medium:
        return Icons.check_circle_outline;
      case QualityLevel.low:
        return Icons.error_outline;
    }
  }

  /// Check if score indicates high quality
  static bool isHighQuality(double score) {
    return score >= highQualityThreshold;
  }

  /// Check if score indicates low quality
  static bool isLowQuality(double score) {
    return score < mediumQualityThreshold;
  }

  /// Check if score indicates medium quality
  static bool isMediumQuality(double score) {
    return score >= mediumQualityThreshold && score < highQualityThreshold;
  }

  /// Format score for display (0.85 -> "85%")
  static String formatScore(double score) {
    return getQualityPercentage(score);
  }

  /// Get emoji for quality level
  static String getQualityEmoji(double score) {
    final level = getQualityLevel(score);
    switch (level) {
      case QualityLevel.high:
        return '✅';
      case QualityLevel.medium:
        return '⚠️';
      case QualityLevel.low:
        return '❌';
    }
  }
}
