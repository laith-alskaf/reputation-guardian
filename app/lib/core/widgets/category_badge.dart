import 'package:flutter/material.dart';
import 'package:reputation_guardian/core/theme/app_theme.dart';

class CategoryBadge extends StatelessWidget {
  final String category;
  final bool isSmall;

  const CategoryBadge({
    super.key,
    required this.category,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (category.toLowerCase()) {
      case 'شكوى':
      case 'complaint':
        color = AppColors.error;
        icon = Icons.report_problem;
        break;
      case 'اقتراح':
      case 'suggestion':
        color = AppColors.primary;
        icon = Icons.lightbulb_outline;
        break;
      case 'مدح':
      case 'praise':
        color = AppColors.success;
        icon = Icons.thumb_up;
        break;
      case 'استفسار':
      case 'inquiry':
        color = AppColors.warning;
        icon = Icons.help_outline;
        break;
      default:
        color = AppColors.neutral;
        icon = Icons.notes;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmall ? 14 : 16,
            color: color,
          ),
          SizedBox(width: isSmall ? 4 : 6),
          Text(
            category,
            style: TextStyle(
              color: color,
              fontSize: isSmall ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
