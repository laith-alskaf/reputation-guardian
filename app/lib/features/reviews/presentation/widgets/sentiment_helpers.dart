import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Sentiment helper utilities for reviews
class SentimentHelpers {
  static Color getSentimentColor(String sentiment) {
    final normalized = sentiment.toLowerCase();
    if (normalized.contains('إيجابي') || normalized.contains('positive')) {
      return AppColors.positive;
    } else if (normalized.contains('سلبي') || normalized.contains('negative')) {
      return AppColors.negative;
    }
    return AppColors.neutral;
  }

  static IconData getSentimentIcon(String sentiment) {
    final normalized = sentiment.toLowerCase();
    if (normalized.contains('إيجابي') || normalized.contains('positive')) {
      return Icons.sentiment_satisfied;
    } else if (normalized.contains('سلبي') || normalized.contains('negative')) {
      return Icons.sentiment_dissatisfied;
    }
    return Icons.sentiment_neutral;
  }

  static String getSentimentLabel(String sentiment) {
    final normalized = sentiment.toLowerCase();
    if (normalized.contains('إيجابي') || normalized.contains('positive')) {
      return 'إيجابي';
    } else if (normalized.contains('سلبي') || normalized.contains('negative')) {
      return 'سلبي';
    }
    return 'محايد';
  }
}
