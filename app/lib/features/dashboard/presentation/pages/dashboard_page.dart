import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reputation_guardian/core/theme/app_theme.dart';
import 'package:reputation_guardian/core/utils/responsive.dart';
import 'package:reputation_guardian/core/widgets/metric_card.dart';
import 'package:reputation_guardian/core/widgets/responsive_scaffold.dart';
import 'package:reputation_guardian/core/widgets/loading_widget.dart';
import 'package:reputation_guardian/core/widgets/error_widget.dart' as custom;
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

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
                    // Welcome Card
                    _buildWelcomeCard(context, data.shopInfo.shopName),
                    SizedBox(height: ResponsiveSpacing.large(context)),

                    // Metrics Grid
                    _buildMetricsGrid(context, data.metrics),
                    SizedBox(height: ResponsiveSpacing.large(context)),

                    // Actions Section
                    _buildActionsSection(context),
                    SizedBox(height: ResponsiveSpacing.large(context)),

                    // Recent Reviews Card
                    _buildRecentReviewsCard(
                        context, data.processedReviews.length),
                  ],
                ),
              );
            }

            // Initial state
            return const Center(
              child: Text('اسحب للأسفل لتحميل البيانات'),
            );
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
                const Icon(
                  Icons.shield,
                  size: 32,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً $shopName! 👋',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
    final crossAxisCount = context.responsive(
      mobile: 2,
      tablet: 3,
      desktop: 5,
    );

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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                        context
                            .read<DashboardBloc>()
                            .add(const GenerateQRCode());
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
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 28,
                ),
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
                  onPressed: () {},
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
}
