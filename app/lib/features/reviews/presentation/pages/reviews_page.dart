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
                      _PaginatedReviewsList(
                        reviews: state.dashboardData.processedReviews,
                        type: 'all',
                        searchQuery: _searchQuery,
                      ),
                      _PaginatedReviewsList(
                        reviews: state.dashboardData.rejectedQualityReviews,
                        type: 'rejected_quality',
                        searchQuery: _searchQuery,
                      ),
                      _PaginatedReviewsList(
                        reviews: state.dashboardData.rejectedIrrelevantReviews,
                        type: 'rejected_irrelevant',
                        searchQuery: _searchQuery,
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
}

class _PaginatedReviewsList extends StatefulWidget {
  final List<dynamic> reviews;
  final String type;
  final String searchQuery;

  const _PaginatedReviewsList({
    required this.reviews,
    required this.type,
    required this.searchQuery,
  });

  @override
  State<_PaginatedReviewsList> createState() => _PaginatedReviewsListState();
}

class _PaginatedReviewsListState extends State<_PaginatedReviewsList>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _filteredReviews = [];
  List<dynamic> _displayedReviews = [];
  static const int _pageSize = 10;
  bool _isLoadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _processReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(_PaginatedReviewsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reviews != widget.reviews ||
        oldWidget.searchQuery != widget.searchQuery) {
      _processReviews();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _processReviews() {
    if (widget.searchQuery.isEmpty) {
      _filteredReviews = widget.reviews;
    } else {
      final query = widget.searchQuery.toLowerCase();
      _filteredReviews = widget.reviews.where((review) {
        final content =
            review['processing']?['concatenated_text']
                ?.toString()
                .toLowerCase() ??
            '';
        final email = review['email']?.toString().toLowerCase() ?? '';
        return content.contains(query) || email.contains(query);
      }).toList();
    }

    _displayedReviews = _filteredReviews.take(_pageSize).toList();
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore || _displayedReviews.length >= _filteredReviews.length) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      final nextBatch = _filteredReviews
          .skip(_displayedReviews.length)
          .take(_pageSize);

      setState(() {
        _displayedReviews.addAll(nextBatch);
        _isLoadingMore = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.reviews.isEmpty) {
      return _buildEmptyState();
    }

    if (_filteredReviews.isEmpty) {
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

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.medium(context),
        vertical: 8,
      ),
      itemCount:
          _displayedReviews.length +
          (_displayedReviews.length < _filteredReviews.length ? 1 : 0),
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _displayedReviews.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _buildReviewCard(_displayedReviews[index]);
      },
    );
  }

  Widget _buildReviewCard(dynamic review) {
    return ReviewCard(
      review: review,
      type: widget.type,
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

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;
    Color iconColor;

    switch (widget.type) {
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
