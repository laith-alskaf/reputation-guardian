import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/enums/review_status_enum.dart';
import '../../../domain/helpers/review_status_helper.dart';

/// Widget to display rejection reason with styled design
class RejectionReasonCard extends StatelessWidget {
  final String? rejectionReason;
  final ReviewStatus status;

  const RejectionReasonCard({
    super.key,
    required this.rejectionReason,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (rejectionReason == null || rejectionReason!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (!status.isRejected) {
      return const SizedBox.shrink();
    }

    final color = ReviewStatusHelper.getStatusColor(status);
    final icon = ReviewStatusHelper.getStatusIcon(status);
    final arabicReason = ReviewStatusHelper.getRejectionReasonArabic(
      rejectionReason,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, size: 22, color: color),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      'سبب الرفض',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  arabicReason,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.text,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Status label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.arabicLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version for inline display
class RejectionReasonBadge extends StatelessWidget {
  final String? rejectionReason;
  final ReviewStatus status;

  const RejectionReasonBadge({
    super.key,
    required this.rejectionReason,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (rejectionReason == null || rejectionReason!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (!status.isRejected) {
      return const SizedBox.shrink();
    }

    final color = ReviewStatusHelper.getStatusColor(status);
    final arabicReason = ReviewStatusHelper.getRejectionReasonArabic(
      rejectionReason,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              arabicReason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
