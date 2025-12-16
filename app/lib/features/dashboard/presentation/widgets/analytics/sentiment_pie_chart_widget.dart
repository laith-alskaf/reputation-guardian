import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/cards/section_card.dart';
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
      return SectionCard(
        title: 'توزيع المشاعر',
        icon: Icons.pie_chart,
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.pie_chart_outline,
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
      );
    }

    return SectionCard(
      title: 'توزيع المشاعر',
      icon: Icons.pie_chart,
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  value: metrics.positiveReviews.toDouble(),
                  title:
                      '${((metrics.positiveReviews / total) * 100).toStringAsFixed(0)}%',
                  color: AppColors.positive,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: metrics.neutralReviews.toDouble(),
                  title:
                      '${((metrics.neutralReviews / total) * 100).toStringAsFixed(0)}%',
                  color: AppColors.warning,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: metrics.negativeReviews.toDouble(),
                  title:
                      '${((metrics.negativeReviews / total) * 100).toStringAsFixed(0)}%',
                  color: AppColors.negative,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
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
    );
  }
}
