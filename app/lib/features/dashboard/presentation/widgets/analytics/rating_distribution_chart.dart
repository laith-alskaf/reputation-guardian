import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/cards/section_card.dart';

/// Rating distribution bar chart widget
class RatingDistributionChart extends StatelessWidget {
  final List<dynamic> reviews;

  const RatingDistributionChart({super.key, required this.reviews});

  Map<int, int> _calculateRatingDistribution() {
    final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var review in reviews) {
      if (review is Map && review.containsKey('stars')) {
        final stars = (review['stars'] as num).round();
        if (stars >= 1 && stars <= 5) {
          distribution[stars] = (distribution[stars] ?? 0) + 1;
        }
      }
    }

    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    final distribution = _calculateRatingDistribution();
    final maxValue = distribution.values.isEmpty
        ? 0
        : distribution.values.reduce((a, b) => a > b ? a : b).toDouble();

    return SectionCard(
      title: 'توزيع التقييمات',
      icon: Icons.bar_chart,
      children: [
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue + 1,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${group.x.toInt() + 1} نجوم\n${rod.toY.toInt()} تقييم',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt() + 1}⭐',
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(5, (index) {
                final rating = index + 1;
                final count = distribution[rating] ?? 0;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: count.toDouble(),
                      color: AppColors.primary,
                      width: 30,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
