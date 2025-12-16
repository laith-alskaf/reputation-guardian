import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/metric_card.dart';
import '../../../domain/entities/dashboard_data.dart';

/// Metrics grid widget for dashboard
class MetricsGrid extends StatelessWidget {
  final Metrics metrics;

  const MetricsGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.medium(context),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // Always show 2 columns on mobile for better layout
        crossAxisCount: context.isMobile
            ? 2
            : context.responsive(mobile: 2, tablet: 3, desktop: 4),
        mainAxisSpacing: ResponsiveSpacing.small(context),
        crossAxisSpacing: ResponsiveSpacing.small(context),
        // Adjust aspect ratio for mobile to make cards look good
        childAspectRatio: context.isMobile ? 1.0 : 1.3,
        children: [
          MetricCard(
            label: 'إجمالي التقييمات',
            value: '${metrics.totalReviews}',
            icon: Icons.rate_review,
            color: AppColors.primary,
          ),
          MetricCard(
            label: 'متوسط التقييم',
            value: '${metrics.averageStars.toStringAsFixed(1)}/5',
            icon: Icons.star,
            color: AppColors.warning,
          ),
          MetricCard(
            label: 'تقييمات إيجابية',
            value: '${metrics.positiveReviews}',
            icon: Icons.thumb_up,
            color: AppColors.positive,
          ),
          MetricCard(
            label: 'تقييمات سلبية',
            value: '${metrics.negativeReviews}',
            icon: Icons.thumb_down,
            color: AppColors.negative,
          ),
        ],
      ),
    );
  }
}
