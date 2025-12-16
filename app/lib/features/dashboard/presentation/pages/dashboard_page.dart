import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reputation_guardian/core/theme/app_theme.dart';
import 'package:reputation_guardian/core/utils/responsive.dart';
import 'package:reputation_guardian/core/utils/app_animations.dart';
import 'package:reputation_guardian/core/widgets/responsive_scaffold.dart';
import 'package:reputation_guardian/core/widgets/loading_widget.dart';
import 'package:reputation_guardian/core/widgets/error_widget.dart' as custom;
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../../reviews/presentation/pages/reviews_page.dart';
import '../../../qr/presentation/widgets/qr_section_widget.dart';
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
                      child: WelcomeCard(shopName: data.shopInfo.shopName),
                    ),
                    SizedBox(height: ResponsiveSpacing.large(context)),

                    // Metrics Grid with stagger
                    AppAnimations.fadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: MetricsGrid(metrics: data.metrics),
                    ),
                    SizedBox(height: ResponsiveSpacing.large(context)),

                    // Sentiment Analysis
                    AppAnimations.fadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: SentimentSection(metrics: data.metrics),
                    ),
                    SizedBox(height: ResponsiveSpacing.large(context)),

                    // QR Code Section
                    if (data.qrCode != null && data.qrCode!.isNotEmpty) ...[
                      AppAnimations.fadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveSpacing.medium(context),
                          ),
                          child: QRSectionWidget(
                            qrCode: data.qrCode!,
                            onDownload: () {
                              context.read<QRBloc>().add(
                                DownloadQRCode(data.qrCode!),
                              );
                            },
                            onShare: () {
                              context.read<QRBloc>().add(
                                ShareQRCode(data.qrCode!),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveSpacing.medium(context),
                      ), // Added spacing between QR widget and buttons
                      // QR Code Actions
                      AppAnimations.fadeSlideIn(
                        delay: const Duration(milliseconds: 350),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveSpacing.medium(context),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<QRBloc>().add(
                                      DownloadQRCode(data.qrCode!),
                                    );
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text('تحميل'),
                                ),
                              ),
                              SizedBox(width: ResponsiveSpacing.small(context)),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<QRBloc>().add(
                                      ShareQRCode(data.qrCode!),
                                    );
                                  },
                                  icon: const Icon(Icons.share),
                                  label: const Text('مشاركة'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveSpacing.large(context)),
                    ],

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
                    icon: Icons.analytics,
                    title: 'التحليلات',
                    subtitle: 'عرض الإحصائيات المفصلة',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsPage(),
                        ),
                      );
                    },
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
                      icon: Icons.analytics,
                      title: 'التحليلات',
                      subtitle: 'عرض الإحصائيات المفصلة',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AnalyticsPage(),
                          ),
                        );
                      },
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
    Color? color, // Added color parameter
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
                  color: (color ?? AppColors.primary).withOpacity(
                    0.1,
                  ), // Used withOpacity
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
