import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/cards/section_card.dart';
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
      child: SectionCard(
        title: 'تحليل المشاعر',
        icon: Icons.analytics,
        children: [
          _buildSentimentRow(
            context,
            'إيجابي',
            metrics.positiveReviews,
            total,
            AppColors.positive,
          ),
          const SizedBox(height: 12),
          _buildSentimentRow(
            context,
            'محايد',
            metrics.neutralReviews,
            total,
            AppColors.warning,
          ),
          const SizedBox(height: 12),
          _buildSentimentRow(
            context,
            'سلبي',
            metrics.negativeReviews,
            total,
            AppColors.negative,
          ),
        ],
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

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? count / total : 0,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            '$count ($percentage%)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
