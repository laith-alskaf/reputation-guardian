import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/charts/chart_legend.dart';
import '../../../domain/entities/dashboard_data.dart';

/// Sentiment pie chart widget with legend
class SentimentPieChartWidget extends StatelessWidget {
  final Metrics metrics;

  const SentimentPieChartWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final total = metrics.totalReviews;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد تقييمات بعد',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    return Container(
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
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'توزيع المشاعر',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 65,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: metrics.positiveReviews.toDouble(),
                        title: '',
                        color: AppColors.positive,
                        radius: 25,
                        badgeWidget: _buildBadge(
                          '${((metrics.positiveReviews / total) * 100).toStringAsFixed(0)}%',
                        ),
                        badgePositionPercentageOffset: 1.1,
                      ),
                      PieChartSectionData(
                        value: metrics.neutralReviews.toDouble(),
                        title: '',
                        color: AppColors.warning,
                        radius: 20,
                        badgeWidget: _buildBadge(
                          '${((metrics.neutralReviews / total) * 100).toStringAsFixed(0)}%',
                        ),
                        badgePositionPercentageOffset: 1.1,
                      ),
                      PieChartSectionData(
                        value: metrics.negativeReviews.toDouble(),
                        title: '',
                        color: AppColors.negative,
                        radius: 18,
                        badgeWidget: _buildBadge(
                          '${((metrics.negativeReviews / total) * 100).toStringAsFixed(0)}%',
                        ),
                        badgePositionPercentageOffset: 1.1,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      'إجمالي التقييمات',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ChartLegend(
            items: [
              LegendItem(
                label: 'إيجابي',
                color: AppColors.positive,
                value: metrics.positiveReviews.toString(),
              ),
              LegendItem(
                label: 'محايد',
                color: AppColors.warning,
                value: metrics.neutralReviews.toString(),
              ),
              LegendItem(
                label: 'سلبي',
                color: AppColors.negative,
                value: metrics.negativeReviews.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
      ),
    );
  }
}
