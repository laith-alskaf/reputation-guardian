import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../domain/enums/review_status_enum.dart';
import '../../domain/enums/quality_flag_enum.dart';
import 'common/quality_score_badge.dart';
import 'common/flags_list_widget.dart';
import 'common/rejection_reason_card.dart';

/// Enhanced review details dialog with comprehensive quality analysis
class ReviewDetailsDialog extends StatelessWidget {
  final dynamic review;

  const ReviewDetailsDialog({super.key, required this.review});

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

  Widget _buildDetailRow(
    String label,
    String value, {
    bool copyable = false,
    BuildContext? context,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SelectableText(
                  value,
                  style: const TextStyle(fontSize: 13),
                  textDirection: label.contains('هاتف')
                      ? TextDirection.ltr
                      : null,
                ),
                if (copyable && context != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: 'نسخ',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      AppSnackbar.showSuccess(context, 'تم النسخ');
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
    final keyThemes = review['analysis']?['key_themes'] ?? [];

    // Quality analysis
    final isProfane = review['processing']?['is_profane'] ?? false;
    final isSuspicious =
        review['analysis']?['quality']?['is_suspicious'] ?? false;
    final flagsList = review['analysis']?['quality']?['flags'];
    final flags = QualityFlag.parseList(flagsList);
    final hasWarnings = isProfane || isSuspicious;

    return Dialog(
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
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          'تفاصيل التقييم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Status badge in header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            status.shortLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Review Status & Rejection Reason
                    if (status.isRejected) ...[
                      RejectionReasonCard(
                        rejectionReason: rejectionReason,
                        status: status,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Review Content
                    _buildDetailSection('المحتوى', Icons.article, [
                      if (content.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            content,
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ),
                    ]),

                    const Divider(height: 32),

                    // Reviewer Info
                    _buildDetailSection('معلومات المقيم', Icons.person, [
                      _buildDetailRow(
                        'البريد الإلكتروني',
                        email,
                        copyable: true,
                        context: context,
                      ),
                      if (phone != null)
                        _buildDetailRow(
                          'رقم الهاتف',
                          phone,
                          copyable: true,
                          context: context,
                        ),
                      _buildDetailRow('التاريخ', displayDate),
                      _buildDetailRow('التقييم', '$stars نجوم⭐'),
                      _buildDetailRow('المشاعر', sentiment.toString()),
                      _buildDetailRow('الفئة', category.toString()),
                    ]),

                    const Divider(height: 32),

                    // Quality Analysis Section
                    _buildDetailSection('تحليل الجودة', Icons.analytics, [
                      // Quality Score
                      if (qualityScore != null) ...[
                        QualityScoreCard(qualityScore: qualityScore),
                        const SizedBox(height: 16),
                      ],

                      // Quality Flags
                      if (flags.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.flag,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'علامات الجودة',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FlagsListWidget(
                          flags: flags,
                          compact: false,
                          showDescriptions: true,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Quality Warnings
                      if (hasWarnings) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.report_problem,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'تحذيرات الجودة',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              if (isProfane)
                                _buildWarningRow(
                                  Icons.warning_amber,
                                  'محتوى غير لائق',
                                  'يحتوي على ألفاظ نابية أو مسيئة',
                                  AppColors.error,
                                ),

                              if (isSuspicious)
                                _buildWarningRow(
                                  Icons.report_problem,
                                  'تقييم مشبوه',
                                  'هذا التقييم قد يكون غير حقيقي أو متلاعب',
                                  AppColors.warning,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ]),

                    const Divider(height: 32),

                    // Generated Content
                    if (summary != null) ...[
                      _buildDetailSection('الملخص', Icons.summarize, [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.info.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            summary.toString(),
                            style: const TextStyle(fontSize: 13, height: 1.6),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    if (insights != null && (insights as List).isNotEmpty) ...[
                      _buildDetailSection('رؤى تحليلية', Icons.lightbulb, [
                        ...((insights)).map(
                          (insight) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      insight.toString(),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    if (suggestedReply != null) ...[
                      _buildDetailSection('الرد المقترح', Icons.reply, [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                suggestedReply.toString(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: suggestedReply.toString(),
                                    ),
                                  );
                                  AppSnackbar.showSuccess(
                                    context,
                                    'تم نسخ الرد المقترح',
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('نسخ الرد'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    // Key Themes
                    if (keyThemes.isNotEmpty) ...[
                      _buildDetailSection('المواضيع الرئيسية', Icons.label, [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (keyThemes as List).map((theme) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                theme.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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
