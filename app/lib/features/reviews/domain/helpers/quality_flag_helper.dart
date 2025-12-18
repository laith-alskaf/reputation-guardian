import 'package:flutter/material.dart';
import '../enums/quality_flag_enum.dart';

/// Helper class for quality flag operations
class QualityFlagHelper {
  const QualityFlagHelper._();

  /// Get the most critical flag from a list based on priority
  static QualityFlag? getMostCritical(List<QualityFlag> flags) {
    if (flags.isEmpty) return null;
    return QualityFlag.getMostImportant(flags);
  }

  /// Get flags sorted by priority (most important first)
  static List<QualityFlag> sortByPriority(List<QualityFlag> flags) {
    final sorted = List<QualityFlag>.from(flags);
    sorted.sort((a, b) => b.priority.compareTo(a.priority));
    return sorted;
  }

  /// Get only severe flags
  static List<QualityFlag> getSevereFlags(List<QualityFlag> flags) {
    return flags.where((f) => f.isSevere).toList();
  }

  /// Check if any flag is severe
  static bool hasSevereFlags(List<QualityFlag> flags) {
    return flags.any((f) => f.isSevere);
  }

  /// Get flags by category
  static Map<String, List<QualityFlag>> groupByCategory(
    List<QualityFlag> flags,
  ) {
    final groups = <String, List<QualityFlag>>{
      'toxicity': [],
      'content_quality': [],
      'length': [],
      'formatting': [],
      'stars': [],
    };

    for (final flag in flags) {
      if (flag == QualityFlag.highToxicity ||
          flag == QualityFlag.possibleToxicity) {
        groups['toxicity']!.add(flag);
      } else if (flag == QualityFlag.emptyContent ||
          flag == QualityFlag.gibberishContent ||
          flag == QualityFlag.repetitiveWords ||
          flag == QualityFlag.repetitiveCharacters) {
        groups['content_quality']!.add(flag);
      } else if (flag == QualityFlag.tooLong || flag == QualityFlag.tooShort) {
        groups['length']!.add(flag);
      } else if (flag == QualityFlag.excessiveSpecialChars) {
        groups['formatting']!.add(flag);
      } else {
        groups['stars']!.add(flag);
      }
    }

    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  /// Get category name in Arabic
  static String getCategoryName(String category) {
    switch (category) {
      case 'toxicity':
        return 'السمية والمحتوى غير اللائق';
      case 'content_quality':
        return 'جودة المحتوى';
      case 'length':
        return 'طول النص';
      case 'formatting':
        return 'التنسيق';
      case 'stars':
        return 'التقييم بالنجوم';
      default:
        return category;
    }
  }

  /// Get summary text for flags
  static String getFlagsSummary(List<QualityFlag> flags) {
    if (flags.isEmpty) return 'لا توجد مشاكل';

    final severFlags = getSevereFlags(flags);
    if (severFlags.isNotEmpty) {
      return 'يحتوي على ${severFlags.length} مشكلة خطيرة';
    }

    if (flags.length == 1) {
      return flags.first.arabicLabel;
    }

    return '${flags.length} علامات جودة';
  }

  /// Get widget to display flag icon and label
  static Widget buildFlagBadge(
    QualityFlag flag, {
    bool showIcon = true,
    bool showLabel = true,
    double iconSize = 14,
    double fontSize = 12,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: flag.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: flag.color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(flag.icon, size: iconSize, color: flag.color),
            if (showLabel) const SizedBox(width: 4),
          ],
          if (showLabel)
            Text(
              flag.arabicLabel,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: flag.color,
              ),
            ),
        ],
      ),
    );
  }

  /// Check if flags contain any toxicity
  static bool hasToxicity(List<QualityFlag> flags) {
    return flags.any(
      (f) => f == QualityFlag.highToxicity || f == QualityFlag.possibleToxicity,
    );
  }

  /// Check if flags indicate stars-only review
  static bool isStarsOnly(List<QualityFlag> flags) {
    return flags.contains(QualityFlag.starsOnly);
  }

  /// Get recommended action based on flags
  static String getRecommendedAction(List<QualityFlag> flags) {
    if (flags.isEmpty) {
      return 'لا توجد إجراءات مطلوبة';
    }

    if (hasToxicity(flags)) {
      return 'يُنصح بحذف أو تعديل هذا التقييم';
    }

    if (hasSevereFlags(flags)) {
      return 'يُنصح بمراجعة هذا التقييم';
    }

    return 'تقييم عادي مع بعض الملاحظات';
  }
}
