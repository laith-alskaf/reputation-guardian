import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reputation_guardian/core/utils/app_animations.dart';
import 'package:reputation_guardian/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:reputation_guardian/features/dashboard/presentation/bloc/dashboard_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/responsive_scaffold.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

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
      padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.05), AppColors.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'ابحث في التقييمات...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        tabs: const [
          Tab(text: 'المقبولة'),
          Tab(text: 'مرفوضة - جودة'),
          Tab(text: 'مرفوضة - غير ذات صلة'),
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
      padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
      itemCount: filteredReviews.length,
      itemBuilder: (context, index) {
        final review = filteredReviews[index];
        return _buildReviewCard(review, type);
      },
    );
  }

  Widget _buildReviewCard(dynamic review, String type) {
    // Extract data
    final sentiment =
        review['overall_sentiment'] ??
        review['analysis']?['sentiment'] ??
        'محايد';
    final sentimentColor = _getSentimentColor(sentiment);
    final stars = review['stars'] ?? review['source']?['rating'] ?? 0;
    final content =
        review['processing']?['concatenated_text'] ?? 'لا يوجد محتوى';
    final email = review['email'] ?? 'مجهول';
    final createdAt = review['created_at'] ?? '';
    final displayDate = createdAt.toString().split('T')[0];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: () => _showReviewDetails(review),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getSentimentIcon(sentiment),
                        color: sentimentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getSentimentLabel(sentiment),
                        style: TextStyle(
                          color: sentimentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildStars(
                        stars is int ? stars : (stars as num).toInt(),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content.toString(),
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      email.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    displayDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (type != 'all') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          review['rejection_reason']?.toString() ??
                              'سبب الرفض غير محدد',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showReviewDetails(dynamic review) {
    final sentiment = review['overall_sentiment'] ?? 'محايد';
    final stars = review['stars'] ?? 0;
    final content =
        review['processing']?['concatenated_text'] ?? 'لا يوجد محتوى';
    final email = review['email'] ?? 'مجهول';
    final createdAt = review['created_at'] ?? '';
    final displayDate = createdAt.toString().split('T')[0];

    // Generated content
    final summary = review['generated_content']?['summary'];
    final insights = review['generated_content']?['actionable_insights'];
    final suggestedReply = review['generated_content']?['suggested_reply'];

    // Analysis
    final category = review['analysis']?['category'] ?? 'عام';
    final qualityScore =
        review['analysis']?['quality']?['quality_score'] ?? 0.0;
    final keyThemes = review['analysis']?['key_themes'] ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تفاصيل التقييم',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meta Info
                      _buildDetailSection('معلومات المقيم', Icons.person, [
                        _buildDetailRow('البريد الإلكتروني', email),
                        _buildDetailRow('التاريخ', displayDate),
                        _buildDetailRow('التقييم', '$stars نجوم⭐'),
                        _buildDetailRow('المشاعر', sentiment.toString()),
                        _buildDetailRow('الفئة', category.toString()),
                      ]),

                      const SizedBox(height: 16),

                      // Original Text
                      _buildDetailSection('النص الأصلي', Icons.comment, [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            content.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ]),

                      if (summary != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection('الملخص', Icons.summarize, [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.info.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              summary.toString(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ]),
                      ],

                      if (insights != null &&
                          insights is List &&
                          insights.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          'الرؤى القابلة للتنفيذ',
                          Icons.lightbulb,
                          insights.map((insight) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(child: Text(insight.toString())),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      if (suggestedReply != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection('الرد المقترح', Icons.reply, [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.positive.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.positive.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              suggestedReply.toString(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: suggestedReply.toString()),
                              );
                              AppSnackbar.showSuccess(context, 'تم نسخ الرد');
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('نسخ الرد'),
                          ),
                        ]),
                      ],

                      if (keyThemes is List && keyThemes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection('المحاور الرئيسية', Icons.topic, [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: keyThemes.map((theme) {
                              return Chip(
                                label: Text(
                                  theme.toString(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
                              );
                            }).toList(),
                          ),
                        ]),
                      ],

                      const SizedBox(height: 16),
                      _buildDetailSection('بيانات التحليل', Icons.analytics, [
                        _buildDetailRow(
                          'درجة الجودة',
                          '${(qualityScore * 100).toStringAsFixed(0)}%',
                        ),
                      ]),
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

  Widget _buildDetailSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
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
                    iconColor.withOpacity(0.1),
                    iconColor.withOpacity(0.05),
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
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: AppColors.warning,
          size: 16,
        );
      }),
    );
  }

  Color _getSentimentColor(String sentiment) {
    final normalized = sentiment.toLowerCase();
    if (normalized.contains('إيجابي') || normalized.contains('positive')) {
      return AppColors.positive;
    } else if (normalized.contains('سلبي') || normalized.contains('negative')) {
      return AppColors.negative;
    }
    return AppColors.neutral;
  }

  IconData _getSentimentIcon(String sentiment) {
    final normalized = sentiment.toLowerCase();
    if (normalized.contains('إيجابي') || normalized.contains('positive')) {
      return Icons.sentiment_satisfied;
    } else if (normalized.contains('سلبي') || normalized.contains('negative')) {
      return Icons.sentiment_dissatisfied;
    }
    return Icons.sentiment_neutral;
  }

  String _getSentimentLabel(String sentiment) {
    final normalized = sentiment.toLowerCase();
    if (normalized.contains('إيجابي') || normalized.contains('positive')) {
      return 'إيجابي';
    } else if (normalized.contains('سلبي') || normalized.contains('negative')) {
      return 'سلبي';
    }
    return 'محايد';
  }
}
