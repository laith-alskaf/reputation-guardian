import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reputation_guardian/core/theme/app_theme.dart';
import 'package:reputation_guardian/core/utils/responsive.dart';
import 'package:reputation_guardian/core/utils/app_animations.dart';
import 'package:reputation_guardian/core/widgets/responsive_scaffold.dart';
import 'package:reputation_guardian/core/widgets/loading_widget.dart';
import 'package:reputation_guardian/core/widgets/error_widget.dart' as custom;
import 'package:reputation_guardian/features/qr/presentation/widgets/qr_dialog.dart';

import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

import '../../../reviews/presentation/pages/reviews_page.dart';
import '../../../reviews/presentation/widgets/review_card.dart';
import '../../../reviews/presentation/widgets/review_details_dialog.dart';
import '../../../reviews/presentation/widgets/sentiment_helpers.dart';

import '../widgets/dashboard/welcome_card.dart';
import '../widgets/dashboard/metrics_grid.dart';
import '../widgets/dashboard/sentiment_section.dart';
import 'analytics_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<DashboardBloc>();
    if (bloc.state is DashboardInitial) {
      bloc.add(const LoadDashboard());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'لوحة التحكم',
      useAnimatedAppBar: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_2, color: Colors.white),
          tooltip: 'رمز QR',
          onPressed: () {
            showDialog(context: context, builder: (_) => const QRDialog());
          },
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<DashboardBloc>().add(const RefreshDashboard());
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: BlocBuilder<DashboardBloc, DashboardState>(
          buildWhen: (previous, current) =>
              previous.runtimeType != current.runtimeType,
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              child: _buildState(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildState(BuildContext context, DashboardState state) {
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
            _animated(WelcomeCard(shopName: data.shopInfo.shopName)),
            _spaceLarge(context),

            _animated(MetricsGrid(metrics: data.metrics)),
            _spaceLarge(context),

            _animated(SentimentSection(metrics: data.metrics)),
            _spaceLarge(context),

            _animated(_buildActionsSection(context)),
            _spaceLarge(context),

            _animated(_buildRecentReviewsCard(context, state.latestReviews)),
            _spaceMedium(context),

            _animated(_buildLastUpdated(context, data.lastUpdated)),
            _spaceLarge(context),
          ],
        ),
      );
    }

    return const Center(child: Text('اسحب للأسفل لتحميل البيانات'));
  }

  /// =============================================================
  /// Helpers
  /// =============================================================

  Widget _animated(Widget child) {
    return RepaintBoundary(child: AppAnimations.appear(child: child));
  }

  SizedBox _spaceLarge(BuildContext context) =>
      SizedBox(height: ResponsiveSpacing.large(context));

  SizedBox _spaceMedium(BuildContext context) =>
      SizedBox(height: ResponsiveSpacing.medium(context));

  /// =============================================================
  /// Actions Section
  /// =============================================================
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
        _spaceMedium(context),
        context.isMobile
            ? Column(
                children: [
                  _actionButton(
                    context,
                    icon: Icons.analytics,
                    title: 'التحليلات',
                    subtitle: 'عرض الإحصائيات المفصلة',
                    onTap: _openAnalytics,
                  ),
                  _spaceMedium(context),
                  _actionButton(
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
                    child: _actionButton(
                      context,
                      icon: Icons.analytics,
                      title: 'التحليلات',
                      subtitle: 'عرض الإحصائيات المفصلة',
                      onTap: _openAnalytics,
                    ),
                  ),
                  SizedBox(width: ResponsiveSpacing.medium(context)),
                  Expanded(
                    child: _actionButton(
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

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
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

  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnalyticsPage()),
    );
  }

  /// =============================================================
  /// Recent Reviews
  /// =============================================================
  Widget _buildRecentReviewsCard(BuildContext context, List<dynamic> reviews) {
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
          _sectionHeader(
            context,
            icon: Icons.rate_review_rounded,
            title: 'أحدث التقييمات',
            actionLabel: 'عرض الكل',
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReviewsPage()),
              );
            },
          ),
          const SizedBox(height: 20),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'لا توجد تقييمات حديثة',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return ReviewCard(
                  review: review,
                  type: 'latest',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AppAnimations.appear(
                        offsetY: 20,
                        child: ReviewDetailsDialog(review: review),
                      ),
                    );
                  },
                  getSentimentColor: SentimentHelpers.getSentimentColor,
                  getSentimentIcon: SentimentHelpers.getSentimentIcon,
                  getSentimentLabel: SentimentHelpers.getSentimentLabel,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }

  /// =============================================================
  /// Last Updated
  /// =============================================================
  Widget _buildLastUpdated(BuildContext context, DateTime lastUpdated) {
    return Center(
      child: Text(
        'آخر تحديث: ${_timeAgo(lastUpdated)}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}
