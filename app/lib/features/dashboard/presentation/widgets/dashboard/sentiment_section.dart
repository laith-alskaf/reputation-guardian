import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../domain/entities/dashboard_data.dart';

/// Sentiment analysis section widget for dashboard
class SentimentSection extends StatelessWidget {
  final Metrics metrics;

  const SentimentSection({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final total = metrics.totalReviews;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.medium(context),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'تحليل المشاعر',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSentimentRow(
              context,
              'إيجابي',
              metrics.positiveReviews,
              total,
              AppColors.positive,
            ),
            const SizedBox(height: 16),
            _buildSentimentRow(
              context,
              'محايد',
              metrics.neutralReviews,
              total,
              AppColors.warning,
            ),
            const SizedBox(height: 16),
            _buildSentimentRow(
              context,
              'سلبي',
              metrics.negativeReviews,
              total,
              AppColors.negative,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentRow(
    BuildContext context,
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    final value = total > 0 ? count / total : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            Text(
              '$count ($percentage%)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              height: 10,
              width:
                  MediaQuery.of(context).size.width *
                  value, // Rough estimate, but works in rows
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
