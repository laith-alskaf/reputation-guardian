import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../domain/enums/review_status_enum.dart';
import '../../domain/enums/quality_flag_enum.dart';
import '../../domain/helpers/review_status_helper.dart';
import 'common/quality_score_badge.dart';
import 'common/flags_list_widget.dart';

/// Enhanced review details dialog with comprehensive quality analysis
class ReviewDetailsDialog extends StatelessWidget {
  final dynamic review;

  const ReviewDetailsDialog({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    // Basic info
    final sentiment =
        review['analysis']?['sentiment'] ??
        review['overall_sentiment'] ??
        'محايد';
    final stars = review['source']?['rating'] ?? review['stars'] ?? 0;
    final content =
        review['processing']?['concatenated_text'] ?? 'لا يوجد محتوى';
    final email = review['email'] ?? 'مجهول';
    final phone = review['source']?['fields']?['phone']?.toString();
    final createdAt = review['created_at'] ?? '';
    final displayDate = createdAt.toString().split('T')[0];
    final status = ReviewStatus.fromString(review['status'] ?? 'processing');
    final rejectionReason = review['rejection_reason'];

    // Generated content
    final summary = review['generated_content']?['summary'];
    final insights = review['generated_content']?['actionable_insights'];
    final suggestedReply = review['generated_content']?['suggested_reply'];

    // Analysis
    final category = review['analysis']?['category'] ?? 'عام';
    final qualityScore = review['analysis']?['quality']?['quality_score'];

    // Quality analysis
    final isProfane = review['processing']?['is_profane'] ?? false;
    final isSuspicious =
        review['analysis']?['quality']?['is_suspicious'] ?? false;
    final flagsList = review['analysis']?['quality']?['flags'];
    final flags = QualityFlag.parseList(flagsList);
    final hasWarnings = isProfane || isSuspicious;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.elevatedShadow,
        ),
        child: Column(
          children: [
            // Premium Header with Gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تفاصيل التقييم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          'تحليل شامل للجودة والمحتوى',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Rejection (Priority)
                    if (status.isRejected) ...[
                      _buildPremiumRejectionCard(status, rejectionReason),
                      const SizedBox(height: 24),
                    ],

                    // Core Content
                    _buildPremiumSection(
                      context,
                      'نص التقييم',
                      Icons.chat_bubble_outline_rounded,
                      [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.05),
                            ),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: SelectableText(
                            content,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // AI Insights (Glass Cards)
                    if (summary != null ||
                        (insights is List && insights.isNotEmpty)) ...[
                      _buildPremiumSection(
                        context,
                        'تحليل الذكاء الاصطناعي',
                        Icons.auto_awesome_rounded,
                        [
                          if (summary != null)
                            _buildAIInsightCard(
                              'الملخص الذكي',
                              summary.toString(),
                              Icons.summarize_rounded,
                              AppColors.info,
                            ),
                          if (insights is List && insights.isNotEmpty)
                            ...insights.map(
                              (insight) => Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _buildAIInsightCard(
                                  'رؤية تحليلية',
                                  insight.toString(),
                                  Icons.lightbulb_outline_rounded,
                                  AppColors.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Suggested Reply
                    if (suggestedReply != null) ...[
                      _buildPremiumSection(
                        context,
                        'الرد المقترح',
                        Icons.reply_rounded,
                        [
                          _buildSuggestedReplyCard(
                            context,
                            suggestedReply.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Quality Analysis
                    _buildPremiumSection(
                      context,
                      'تحليل الجودة',
                      Icons.verified_user_rounded,
                      [
                        if (qualityScore != null) ...[
                          QualityScoreBadge(qualityScore: qualityScore),
                          const SizedBox(height: 16),
                        ],
                        if (flags.isNotEmpty)
                          FlagsListWidget(
                            flags: flags,
                            compact: false,
                            showDescriptions: true,
                          ),
                        if (hasWarnings) ...[
                          const SizedBox(height: 16),
                          _buildPremiumWarningBox(isProfane, isSuspicious),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Reviewer Info Grid
                    _buildPremiumSection(
                      context,
                      'معلومات المقيم',
                      Icons.person_outline_rounded,
                      [
                        _buildInfoGrid(
                          context,
                          email,
                          phone,
                          displayDate,
                          stars,
                          sentiment,
                          category,
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
    );
  }

  Widget _buildPremiumSection(
    BuildContext context,
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildAIInsightCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedReplyCard(BuildContext context, String reply) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            reply,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reply));
              AppSnackbar.showSuccess(context, 'تم نسخ الرد المقترح');
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('نسخ الرد المقترح'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumRejectionCard(ReviewStatus status, dynamic reason) {
    final color = ReviewStatusHelper.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.gpp_bad_rounded, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تقييم مرفوض',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  ReviewStatusHelper.getRejectionReasonArabic(reason),
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumWarningBox(bool isProfane, bool isSuspicious) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          if (isProfane)
            _buildWarningRow(
              Icons.warning_amber_rounded,
              'محتوى مسيئ',
              'يحتوي على ألفاظ غير لائقة',
              AppColors.error,
            ),
          if (isSuspicious)
            _buildWarningRow(
              Icons.report_problem_rounded,
              'نشاط مشبوه',
              'قد يكون تقييم غير حقيقي',
              AppColors.warning,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(
    BuildContext context,
    String email,
    String? phone,
    String date,
    int stars,
    dynamic sentiment,
    dynamic category,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        children: [
          _buildInfoItem('البريد', email, Icons.email_outlined),
          if (phone != null)
            _buildInfoItem('الهاتف', phone, Icons.phone_outlined),
          _buildInfoItem('التاريخ', date, Icons.calendar_today_outlined),
          _buildInfoItem('التقييم', '$stars نجوم', Icons.star_outline_rounded),
          _buildInfoItem(
            'المشاعر',
            sentiment.toString(),
            Icons.sentiment_satisfied_alt_rounded,
          ),
          _buildInfoItem('الفئة', category.toString(), Icons.category_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningRow(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
