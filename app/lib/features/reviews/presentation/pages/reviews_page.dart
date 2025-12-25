import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reputation_guardian/core/utils/app_animations.dart';
import 'package:reputation_guardian/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:reputation_guardian/features/dashboard/presentation/bloc/dashboard_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../widgets/review_card.dart';
import '../widgets/review_details_dialog.dart';
import '../widgets/sentiment_helpers.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'التقييمات',
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Tabs
          _buildTabs(),

          // Reviews List
          Expanded(
            child: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is DashboardError) {
                  return Center(child: Text(state.message));
                }

                if (state is DashboardLoaded) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReviewsList(
                        context,
                        state.dashboardData.processedReviews,
                        'all',
                      ),
                      _buildReviewsList(
                        context,
                        state.dashboardData.rejectedQualityReviews,
                        'rejected_quality',
                      ),
                      _buildReviewsList(
                        context,
                        state.dashboardData.rejectedIrrelevantReviews,
                        'rejected_irrelevant',
                      ),
                    ],
                  );
                }

                return const Center(child: Text('لا توجد بيانات'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'البحث في التقييمات...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          fontFamily: 'Cairo',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontFamily: 'Cairo',
        ),
        tabs: const [
          Tab(text: 'المقبولة'),
          Tab(text: 'مرفوضة - جودة'),
          Tab(text: 'مرفوضة - صلة'),
        ],
      ),
    );
  }

  Widget _buildReviewsList(
    BuildContext context,
    List<dynamic> reviews,
    String type,
  ) {
    if (reviews.isEmpty) {
      return _buildEmptyState(type);
    }

    final filteredReviews = reviews.where((review) {
      if (_searchQuery.isEmpty) return true;
      final content =
          review['processing']?['concatenated_text']
              ?.toString()
              .toLowerCase() ??
          '';
      final email = review['email']?.toString().toLowerCase() ?? '';
      return content.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredReviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('لا توجد نتائج للبحث'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.medium(context),
        vertical: 8,
      ),
      itemCount: filteredReviews.length,
      physics: const BouncingScrollPhysics(),
      addAutomaticKeepAlives: true,
      itemBuilder: (context, index) {
        final review = filteredReviews[index];
        return _buildReviewCard(review, type);
      },
    );
  }

  Widget _buildReviewCard(dynamic review, String type) {
    return ReviewCard(
      review: review,
      type: type,
      onTap: () => _showReviewDetails(review),
      getSentimentColor: SentimentHelpers.getSentimentColor,
      getSentimentIcon: SentimentHelpers.getSentimentIcon,
      getSentimentLabel: SentimentHelpers.getSentimentLabel,
    );
  }

  void _showReviewDetails(dynamic review) {
    showDialog(
      context: context,
      builder: (context) => ReviewDetailsDialog(review: review),
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    String subtitle;
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'all':
        message = 'لا توجد تقييمات مقبولة';
        subtitle = 'سيظهر هنا التقييمات المعتمدة';
        icon = Icons.rate_review_outlined;
        iconColor = AppColors.primary;
        break;
      case 'rejected_quality':
        message = 'لا توجد تقييمات مرفوضة';
        subtitle = 'التقييمات المرفوضة بسبب الجودة ستظهر هنا';
        icon = Icons.thumb_down_outlined;
        iconColor = AppColors.error;
        break;
      case 'rejected_irrelevant':
        message = 'لا توجد تقييمات غير ذات صلة';
        subtitle = 'التقييمات غير المرتبطة بنشاطك ستظهر هنا';
        icon = Icons.block;
        iconColor = AppColors.warning;
        break;
      default:
        message = 'لا توجد تقييمات';
        subtitle = 'ابدأ باستقبال التقييمات';
        icon = Icons.info_outline;
        iconColor = AppColors.info;
    }

    return AppAnimations.scaleIn(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.1),
                    iconColor.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(icon, size: 64, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
