import 'package:flutter/material.dart';
import 'package:reputation_guardian/core/theme/app_theme.dart';
import 'package:reputation_guardian/core/utils/responsive.dart';
import 'package:reputation_guardian/core/widgets/responsive_scaffold.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'التقييمات',
      body: Column(
        children: [
          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary.withOpacity(0.1),
              ),
              tabs: const [
                Tab(text: 'المقبولة'),
                Tab(text: 'منخفضة الجودة'),
                Tab(text: 'غير ذات صلة'),
              ],
            ),
          ),
          SizedBox(height: ResponsiveSpacing.medium(context)),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الكل'),
                _buildFilterChip('إيجابي'),
                _buildFilterChip('سلبي'),
                _buildFilterChip('محايد'),
              ],
            ),
          ),
          SizedBox(height: ResponsiveSpacing.medium(context)),

          // Reviews List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReviewsList('processed'),
                _buildReviewsList('rejected_quality'),
                _buildReviewsList('rejected_irrelevant'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? label : 'الكل';
          });
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildReviewsList(String type) {
    // This will be connected to BLoC later
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد تقييمات',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
