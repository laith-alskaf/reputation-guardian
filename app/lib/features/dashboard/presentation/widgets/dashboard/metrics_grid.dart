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
      child: context.isMobile
          ? Column(
              children: [
                MetricCard(
                  label: 'إجمالي التقييمات',
                  value: '${metrics.totalReviews}',
                  icon: Icons.rate_review,
                  color: AppColors.primary,
                ),
                SizedBox(height: ResponsiveSpacing.small(context)),
                MetricCard(
                  label: 'متوسط التقييم',
                  value: '${metrics.averageStars.toStringAsFixed(1)}/5',
                  icon: Icons.star,
                  color: AppColors.warning,
                ),
                SizedBox(height: ResponsiveSpacing.small(context)),
                MetricCard(
                  label: 'تقييمات إيجابية',
                  value: '${metrics.positiveReviews}',
                  icon: Icons.thumb_up,
                  color: AppColors.positive,
                ),
                SizedBox(height: ResponsiveSpacing.small(context)),
                MetricCard(
                  label: 'تقييمات سلبية',
                  value: '${metrics.negativeReviews}',
                  icon: Icons.thumb_down,
                  color: AppColors.negative,
                ),
              ],
            )
          : GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: ResponsiveSpacing.small(context),
              crossAxisSpacing: ResponsiveSpacing.small(context),
              childAspectRatio: context.isTablet ? 2.5 : 1.8,
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
