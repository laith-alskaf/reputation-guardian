import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/app_snackbar.dart';

/// Review details dialog widget
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

  @override
  Widget build(BuildContext context) {
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
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.3),
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
                            color: AppColors.positive.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.positive.withValues(alpha: 0.3),
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
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
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
    );
  }
}
