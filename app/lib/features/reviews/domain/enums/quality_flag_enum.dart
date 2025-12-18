import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Quality flags that indicate specific issues or characteristics of a review
enum QualityFlag {
  /// Review contains only star rating, no text
  starsOnly,

  /// Review has positive stars (4-5)
  positiveStars,

  /// Review has negative stars (1-2)
  negativeStars,

  /// Review has neutral stars (3)
  neutralStars,

  /// Review has no content
  emptyContent,

  /// Review contains gibberish or nonsense text
  gibberishContent,

  /// Review is too long (>200 words)
  tooLong,

  /// Review is too short (<2 words)
  tooShort,

  /// Review has repetitive characters (e.g., 'aaaaa')
  repetitiveCharacters,

  /// Review has repetitive words
  repetitiveWords,

  /// Review has excessive special characters
  excessiveSpecialChars,

  /// Review contains high toxicity
  highToxicity,

  /// Review contains possible toxicity
  possibleToxicity;

  /// Get Arabic label for the flag
  String get arabicLabel {
    switch (this) {
      case QualityFlag.starsOnly:
        return 'نجوم فقط';
      case QualityFlag.positiveStars:
        return 'نجوم إيجابية';
      case QualityFlag.negativeStars:
        return 'نجوم سلبية';
      case QualityFlag.neutralStars:
        return 'نجوم محايدة';
      case QualityFlag.emptyContent:
        return 'محتوى فارغ';
      case QualityFlag.gibberishContent:
        return 'محتوى غير مفهوم';
      case QualityFlag.tooLong:
        return 'طويل جداً';
      case QualityFlag.tooShort:
        return 'قصير جداً';
      case QualityFlag.repetitiveCharacters:
        return 'تكرار حروف';
      case QualityFlag.repetitiveWords:
        return 'تكرار كلمات';
      case QualityFlag.excessiveSpecialChars:
        return 'رموز كثيرة';
      case QualityFlag.highToxicity:
        return 'سمية عالية';
      case QualityFlag.possibleToxicity:
        return 'سمية محتملة';
    }
  }

  /// Get detailed Arabic description
  String get description {
    switch (this) {
      case QualityFlag.starsOnly:
        return 'التقييم يحتوي على نجوم فقط بدون نص';
      case QualityFlag.positiveStars:
        return 'تقييم إيجابي (4-5 نجوم)';
      case QualityFlag.negativeStars:
        return 'تقييم سلبي (1-2 نجوم)';
      case QualityFlag.neutralStars:
        return 'تقييم محايد (3 نجوم)';
      case QualityFlag.emptyContent:
        return 'التقييم لا يحتوي على أي محتوى نصي';
      case QualityFlag.gibberishContent:
        return 'المحتوى غير واضح أو عشوائي';
      case QualityFlag.tooLong:
        return 'النص طويل جداً (أكثر من 200 كلمة)';
      case QualityFlag.tooShort:
        return 'النص قصير جداً (أقل من كلمتين)';
      case QualityFlag.repetitiveCharacters:
        return 'تكرار مفرط للحروف (مثل: ااااا)';
      case QualityFlag.repetitiveWords:
        return 'تكرار مفرط للكلمات نفسها';
      case QualityFlag.excessiveSpecialChars:
        return 'كثرة الرموز الخاصة والأحرف غير المفيدة';
      case QualityFlag.highToxicity:
        return 'يحتوي على لغة سامة أو عنيفة أو مسيئة';
      case QualityFlag.possibleToxicity:
        return 'قد يحتوي على محتوى غير لائق';
    }
  }

  /// Get icon for the flag
  IconData get icon {
    switch (this) {
      case QualityFlag.highToxicity:
      case QualityFlag.possibleToxicity:
        return Icons.warning_amber_rounded;
      case QualityFlag.emptyContent:
        return Icons.text_fields_outlined;
      case QualityFlag.starsOnly:
      case QualityFlag.positiveStars:
      case QualityFlag.negativeStars:
      case QualityFlag.neutralStars:
        return Icons.star_outline;
      case QualityFlag.repetitiveWords:
      case QualityFlag.repetitiveCharacters:
        return Icons.repeat;
      case QualityFlag.tooLong:
        return Icons.article_outlined;
      case QualityFlag.tooShort:
        return Icons.short_text;
      case QualityFlag.gibberishContent:
        return Icons.help_outline;
      case QualityFlag.excessiveSpecialChars:
        return Icons.code;
    }
  }

  /// Get color for the flag
  Color get color {
    switch (this) {
      case QualityFlag.highToxicity:
        return AppColors.error;
      case QualityFlag.possibleToxicity:
        return AppColors.warning;
      case QualityFlag.positiveStars:
        return AppColors.success;
      case QualityFlag.negativeStars:
        return AppColors.error;
      case QualityFlag.neutralStars:
        return AppColors.info;
      case QualityFlag.emptyContent:
      case QualityFlag.gibberishContent:
      case QualityFlag.repetitiveWords:
      case QualityFlag.repetitiveCharacters:
      case QualityFlag.excessiveSpecialChars:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Get priority for display (higher = more important)
  int get priority {
    switch (this) {
      case QualityFlag.highToxicity:
        return 100;
      case QualityFlag.possibleToxicity:
        return 90;
      case QualityFlag.emptyContent:
        return 80;
      case QualityFlag.gibberishContent:
        return 70;
      case QualityFlag.repetitiveWords:
        return 60;
      case QualityFlag.repetitiveCharacters:
        return 55;
      case QualityFlag.excessiveSpecialChars:
        return 50;
      case QualityFlag.tooShort:
        return 40;
      case QualityFlag.tooLong:
        return 30;
      case QualityFlag.negativeStars:
        return 20;
      case QualityFlag.positiveStars:
        return 15;
      case QualityFlag.neutralStars:
        return 10;
      case QualityFlag.starsOnly:
        return 5;
    }
  }

  /// Check if flag indicates a serious issue
  bool get isSevere =>
      this == QualityFlag.highToxicity ||
      this == QualityFlag.emptyContent ||
      this == QualityFlag.gibberishContent;

  /// Convert from backend string value
  static QualityFlag? fromString(String value) {
    switch (value) {
      case 'stars_only':
        return QualityFlag.starsOnly;
      case 'positive_stars':
        return QualityFlag.positiveStars;
      case 'negative_stars':
        return QualityFlag.negativeStars;
      case 'neutral_stars':
        return QualityFlag.neutralStars;
      case 'empty_content':
        return QualityFlag.emptyContent;
      case 'gibberish_content':
        return QualityFlag.gibberishContent;
      case 'too_long':
        return QualityFlag.tooLong;
      case 'too_short':
        return QualityFlag.tooShort;
      case 'repetitive_characters':
        return QualityFlag.repetitiveCharacters;
      case 'repetitive_words':
        return QualityFlag.repetitiveWords;
      case 'excessive_special_chars':
        return QualityFlag.excessiveSpecialChars;
      case 'high_toxicity':
        return QualityFlag.highToxicity;
      case 'possible_toxicity':
        return QualityFlag.possibleToxicity;
      default:
        return null;
    }
  }

  /// Convert to backend string value
  String toBackendString() {
    switch (this) {
      case QualityFlag.starsOnly:
        return 'stars_only';
      case QualityFlag.positiveStars:
        return 'positive_stars';
      case QualityFlag.negativeStars:
        return 'negative_stars';
      case QualityFlag.neutralStars:
        return 'neutral_stars';
      case QualityFlag.emptyContent:
        return 'empty_content';
      case QualityFlag.gibberishContent:
        return 'gibberish_content';
      case QualityFlag.tooLong:
        return 'too_long';
      case QualityFlag.tooShort:
        return 'too_short';
      case QualityFlag.repetitiveCharacters:
        return 'repetitive_characters';
      case QualityFlag.repetitiveWords:
        return 'repetitive_words';
      case QualityFlag.excessiveSpecialChars:
        return 'excessive_special_chars';
      case QualityFlag.highToxicity:
        return 'high_toxicity';
      case QualityFlag.possibleToxicity:
        return 'possible_toxicity';
    }
  }

  /// Parse list of flags from backend
  static List<QualityFlag> parseList(List<dynamic>? flagsList) {
    if (flagsList == null || flagsList.isEmpty) return [];

    return flagsList
        .map((f) => fromString(f.toString()))
        .where((f) => f != null)
        .cast<QualityFlag>()
        .toList();
  }

  /// Get most important flag from a list (highest priority)
  static QualityFlag? getMostImportant(List<QualityFlag> flags) {
    if (flags.isEmpty) return null;

    return flags.reduce((a, b) => a.priority > b.priority ? a : b);
  }
}
