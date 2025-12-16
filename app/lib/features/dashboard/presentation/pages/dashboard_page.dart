import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reputation_guardian/core/theme/app_theme.dart';
import 'package:reputation_guardian/core/utils/responsive.dart';
import 'package:reputation_guardian/core/utils/app_animations.dart';
import 'package:reputation_guardian/core/widgets/metric_card.dart';
import 'package:reputation_guardian/core/widgets/responsive_scaffold.dart';
import 'package:reputation_guardian/core/widgets/loading_widget.dart';
import 'package:reputation_guardian/core/widgets/error_widget.dart' as custom;
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import 'reviews_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data on init
    context.read<DashboardBloc>().add(const LoadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'لوحة التحكم',
      useAnimatedAppBar: true,
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<DashboardBloc>().add(const RefreshDashboard());
          await Future.delayed(const Duration(seconds: 1));
        },
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const LoadingWidget(message: 'جاري تحميل البيانات...');
            }

            if (state is DashboardError) {
              return custom.ErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<DashboardBloc>().add(const LoadDashboard());
                },
              );
            }

            if (state is DashboardLoaded) {
              final data = state.dashboardData;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome Card with animation
                    AppAnimations.fadeSlideIn(
                      child: _buildWelcomeCard(context, data.shopInfo.shopName),
                    ),
                    SizedBox(height: ResponsiveSpacing.large(context)),

                    // Metrics Grid with stagger
                    AppAnimations.fadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: _buildMetricsGrid(context, data.metrics),
                    ),
                    SizedBox(height: ResponsiveSpacing.large(context)),

                    // Sentiment Analysis
                    AppAnimations.fadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: _buildSentimentAnalysis(context, data.metrics),
                    ),
                    SizedBox(height: ResponsiveSpacing.large(context)),

                    // QR Code Section
                    if (data.qrCode != null && data.qrCode!.isNotEmpty)
                      AppAnimations.fadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: Column(
                          children: [
                            _buildQRCodeSection(context, data.qrCode!),
                            SizedBox(height: ResponsiveSpacing.large(context)),
                          ],
                        ),
                      ),

                    // Actions Section
                    AppAnimations.fadeSlideIn(
                      delay: const Duration(milliseconds: 400),
                      child: _buildActionsSection(context),
                    ),
                    SizedBox(height: ResponsiveSpacing.large(context)),

                    // Recent Reviews Card
                    AppAnimations.fadeSlideIn(
                      delay: const Duration(milliseconds: 500),
                      child: _buildRecentReviewsCard(
                        context,
                        data.processedReviews.length,
                      ),
                    ),

                    SizedBox(height: ResponsiveSpacing.medium(context)),

                    // Last Updated
                    AppAnimations.fadeSlideIn(
                      delay: const Duration(milliseconds: 600),
                      child: _buildLastUpdated(context, data.lastUpdated),
                    ),

                    SizedBox(height: ResponsiveSpacing.large(context)),
                  ],
                ),
              );
            }

            // Initial state
            return const Center(child: Text('اسحب للأسفل لتحميل البيانات'));
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String shopName) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield, size: 32, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً $shopName! 👋',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'إليك نظرة سريعة على تقييمات متجرك',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, dynamic metrics) {
    final crossAxisCount = context.responsive(mobile: 2, tablet: 3, desktop: 5);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: 1.0,
      mainAxisSpacing: ResponsiveSpacing.medium(context),
      crossAxisSpacing: ResponsiveSpacing.medium(context),
      children: [
        MetricCard(
          icon: Icons.star,
          value: metrics.averageStars.toStringAsFixed(1),
          label: 'متوسط النجوم',
          color: AppColors.warning,
        ),
        MetricCard(
          icon: Icons.rate_review,
          value: metrics.totalReviews.toString(),
          label: 'إجمالي التقييمات',
          color: AppColors.primary,
        ),
        MetricCard(
          icon: Icons.thumb_up,
          value: metrics.positiveReviews.toString(),
          label: 'إيجابية',
          color: AppColors.positive,
        ),
        MetricCard(
          icon: Icons.thumb_down,
          value: metrics.negativeReviews.toString(),
          label: 'سلبية',
          color: AppColors.negative,
        ),
        MetricCard(
          icon: Icons.trending_flat,
          value: metrics.neutralReviews.toString(),
          label: 'محايدة',
          color: AppColors.neutral,
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إجراءات سريعة',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: ResponsiveSpacing.medium(context)),
        context.isMobile
            ? Column(
                children: [
                  _buildActionButton(
                    context,
                    icon: Icons.qr_code,
                    title: 'رمز QR',
                    subtitle: 'عرض وتحميل رمز QR',
                    onTap: () {
                      context.read<DashboardBloc>().add(const GenerateQRCode());
                    },
                  ),
                  SizedBox(height: ResponsiveSpacing.small(context)),
                  _buildActionButton(
                    context,
                    icon: Icons.analytics,
                    title: 'التحليلات',
                    subtitle: 'عرض الإحصائيات المفصلة',
                    onTap: () {},
                  ),
                  SizedBox(height: ResponsiveSpacing.small(context)),
                  _buildActionButton(
                    context,
                    icon: Icons.file_download,
                    title: 'تصدير البيانات',
                    subtitle: 'تحميل التقارير',
                    onTap: () {},
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.qr_code,
                      title: 'رمز QR',
                      subtitle: 'عرض وتحميل رمز QR',
                      onTap: () {
                        context.read<DashboardBloc>().add(
                          const GenerateQRCode(),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: ResponsiveSpacing.medium(context)),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.analytics,
                      title: 'التحليلات',
                      subtitle: 'عرض الإحصائيات المفصلة',
                      onTap: () {},
                    ),
                  ),
                  SizedBox(width: ResponsiveSpacing.medium(context)),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.file_download,
                      title: 'تصدير البيانات',
                      subtitle: 'تحميل التقارير',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReviewsCard(BuildContext context, int reviewCount) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'أحدث التقييمات',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReviewsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('عرض الكل'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.rate_review_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      reviewCount > 0
                          ? 'لديك $reviewCount تقييم'
                          : 'لا توجد تقييمات جديدة',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentAnalysis(BuildContext context, dynamic metrics) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.medium(context),
      ),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'تحليل المشاعر',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              metrics.totalReviews > 0
                  ? Column(
                      children: [
                        _buildSentimentBar(
                          'إيجابي',
                          metrics.positiveReviews,
                          metrics.totalReviews,
                          AppColors.positive,
                        ),
                        const SizedBox(height: 12),
                        _buildSentimentBar(
                          'محايد',
                          metrics.neutralReviews,
                          metrics.totalReviews,
                          AppColors.neutral,
                        ),
                        const SizedBox(height: 12),
                        _buildSentimentBar(
                          'سلبي',
                          metrics.negativeReviews,
                          metrics.totalReviews,
                          AppColors.negative,
                        ),
                      ],
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.sentiment_satisfied_alt,
                              size: 48,
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'لا توجد تقييمات بعد',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentimentBar(String label, int count, int total, Color color) {
    final percentage = (count / total * 100).toStringAsFixed(0);
    final ratio = count / total;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 24,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
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

  Widget _buildQRCodeSection(BuildContext context, String qrCode) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.medium(context),
      ),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'رمز QR الخاص بك',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Decode base64 QR code
                      _buildQRImage(qrCode),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Download QR
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('تحميل'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Share QR
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('مشاركة'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRImage(String qrCode) {
    try {
      // Try to decode as base64
      final bytes = base64Decode(qrCode);
      return Image.memory(
        bytes,
        width: 200,
        height: 200,
        errorBuilder: (context, error, stackTrace) {
          return _buildQRErrorWidget();
        },
      );
    } catch (e) {
      // If not base64, try as URL
      if (qrCode.startsWith('http')) {
        return Image.network(
          qrCode,
          width: 200,
          height: 200,
          errorBuilder: (context, error, stackTrace) {
            return _buildQRErrorWidget();
          },
        );
      }
      return _buildQRErrorWidget();
    }
  }

  Widget _buildQRErrorWidget() {
    return Container(
      width: 200,
      height: 200,
      color: AppColors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            'خطأ في عرض QR',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(BuildContext context, DateTime lastUpdated) {
    final timeAgo = _getTimeAgo(lastUpdated);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.medium(context),
      ),
      child: Center(
        child: Text(
          'آخر تحديث: $timeAgo',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}
