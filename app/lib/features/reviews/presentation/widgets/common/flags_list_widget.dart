import 'package:flutter/material.dart';
import '../../../domain/enums/quality_flag_enum.dart';
import '../../../domain/helpers/quality_flag_helper.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget to display a list of quality flags
class FlagsListWidget extends StatelessWidget {
  final List<QualityFlag> flags;
  final bool compact;
  final bool showDescriptions;
  final int? maxFlags;

  const FlagsListWidget({
    super.key,
    required this.flags,
    this.compact = false,
    this.showDescriptions = false,
    this.maxFlags,
  });

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedFlags = QualityFlagHelper.sortByPriority(flags);
    final displayFlags = maxFlags != null
        ? sortedFlags.take(maxFlags!).toList()
        : sortedFlags;

    if (compact) {
      return _buildCompactView(displayFlags);
    } else {
      return _buildExpandedView(displayFlags);
    }
  }

  Widget _buildCompactView(List<QualityFlag> displayFlags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: displayFlags.map((flag) {
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
              Icon(flag.icon, size: 14, color: flag.color),
              const SizedBox(width: 4),
              Text(
                flag.arabicLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: flag.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpandedView(List<QualityFlag> displayFlags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: displayFlags.map((flag) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: flag.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: flag.color.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: flag.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(flag.icon, size: 18, color: flag.color),
                ),

                const SizedBox(width: 12),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flag.arabicLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: flag.color,
                        ),
                      ),
                      if (showDescriptions) ...[
                        const SizedBox(height: 4),
                        Text(
                          flag.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Widget to display flags grouped by category
class GroupedFlagsWidget extends StatelessWidget {
  final List<QualityFlag> flags;

  const GroupedFlagsWidget({super.key, required this.flags});

  @override
  Widget build(BuildContext context) {
    final groupedFlags = QualityFlagHelper.groupByCategory(flags);

    if (groupedFlags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedFlags.entries.map((entry) {
        final categoryName = QualityFlagHelper.getCategoryName(entry.key);
        final categoryFlags = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),

              // Flags in this category
              FlagsListWidget(flags: categoryFlags, compact: true),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Single flag badge for inline display
class FlagBadge extends StatelessWidget {
  final QualityFlag flag;
  final bool showIcon;
  final bool showLabel;

  const FlagBadge({
    super.key,
    required this.flag,
    this.showIcon = true,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
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
            Icon(flag.icon, size: 14, color: flag.color),
            if (showLabel) const SizedBox(width: 4),
          ],
          if (showLabel)
            Text(
              flag.arabicLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: flag.color,
              ),
            ),
        ],
      ),
    );
  }
}
