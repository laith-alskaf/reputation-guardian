import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/app_animations.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/entities/dashboard_data.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/analytics/period_filter_widget.dart';
import '../widgets/analytics/rating_distribution_chart.dart';
import '../widgets/analytics/sentiment_pie_chart_widget.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _selectedPeriod = 'week';

  // Helper method to calculate timeline data
  List<FlSpot> _calculateTimelineData(List<dynamic> reviews) {
    if (reviews.isEmpty) {
      return List.generate(7, (index) => FlSpot(index.toDouble(), 0));
    }

    final weekData = List<double>.filled(7, 0);
    final weekCounts = List<int>.filled(7, 0);

    for (var review in reviews) {
      if (review is Map &&
          review.containsKey('created_at') &&
          review.containsKey('stars')) {
        try {
          final date = DateTime.parse(review['created_at'].toString());
          final dayOfWeek = date.weekday % 7;
          final stars = (review['stars'] as num).toDouble();

          weekData[dayOfWeek] += stars;
          weekCounts[dayOfWeek]++;
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < 7; i++) {
      final avg = weekCounts[i] > 0 ? weekData[i] / weekCounts[i] : 0;
      spots.add(FlSpot(i.toDouble(), avg.toDouble()));
    }

    return spots;
  }

  // Helper method to filter reviews by period
  List<dynamic> _filterReviewsByPeriod(List<dynamic> reviews) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'day':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    return reviews.where((review) {
      if (review is Map && review.containsKey('created_at')) {
        try {
          final date = DateTime.parse(review['created_at'].toString());
          return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
        } catch (e) {
          return false;
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'التحليلات',
      showBackButton: true,
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is! DashboardLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = state.dashboardData;
          final metrics = data.metrics;
          final allReviews = data.processedReviews;
          final reviews = _filterReviewsByPeriod(allReviews);

          return SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Period Selector
                AppAnimations.fadeSlideIn(
                  child: PeriodFilterWidget(
                    selectedPeriod: _selectedPeriod,
                    onPeriodChanged: (period) {
                      setState(() {
                        _selectedPeriod = period;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Overview Cards
                AppAnimations.fadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: _buildOverviewCards(metrics),
                ),
                const SizedBox(height: 24),

                // Rating Distribution Chart
                AppAnimations.fadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: RatingDistributionChart(reviews: reviews),
                ),
                const SizedBox(height: 24),

                // Sentiment Trend Chart
                AppAnimations.fadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: SentimentPieChartWidget(metrics: metrics),
                ),
                const SizedBox(height: 24),

                // Reviews Timeline
                AppAnimations.fadeSlideIn(
                  delay: const Duration(milliseconds: 400),
                  child: _buildReviewsTimeline(reviews),
                ),
                const SizedBox(height: 24),

                // Key Insights
                AppAnimations.fadeSlideIn(
                  delay: const Duration(milliseconds: 500),
                  child: _buildKeyInsights(metrics),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards(Metrics metrics) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'متوسط التقييم',
            '${metrics.averageStars.toStringAsFixed(1)}/5',
            Icons.star,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'إجمالي التقييمات',
            '${metrics.totalReviews}',
            Icons.rate_review,
            AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTimeline(List<dynamic> reviews) {
    final timelineData = _calculateTimelineData(reviews);
    final hasData = timelineData.any((spot) => spot.y > 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اتجاه التقييمات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: !hasData
                ? const Center(
                    child: Text(
                      'لا توجد تقييمات كافية لعرض الاتجاه',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = [
                                'الاثنين',
                                'الثلاثاء',
                                'الأربعاء',
                                'الخميس',
                                'الجمعة',
                                'السبت',
                                'الأحد',
                              ];
                              if (value.toInt() >= 0 &&
                                  value.toInt() < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: 5,
                      lineBarsData: [
                        LineChartBarData(
                          spots: timelineData,
                          isCurved: true,
                          gradient: AppColors.primaryGradient,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.2),
                                AppColors.primary.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInsights(Metrics metrics) {
    final total = metrics.totalReviews;
    final positive = metrics.positiveReviews;
    final avgStars = metrics.averageStars;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.info),
              const SizedBox(width: 12),
              const Text(
                'رؤى رئيسية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            '${total > 0 ? (positive / total * 100).toStringAsFixed(0) : 0}% من التقييمات إيجابية',
            Icons.trending_up,
            AppColors.positive,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'متوسط التقييم ${avgStars.toStringAsFixed(1)} نجوم',
            Icons.star,
            AppColors.warning,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'تم تلقي $total تقييم حتى الآن',
            Icons.analytics,
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String text, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
        ),
      ],
    );
  }
}
