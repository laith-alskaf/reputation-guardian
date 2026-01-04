import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../domain/enums/review_status_enum.dart';
import '../../domain/enums/quality_flag_enum.dart';
import '../../domain/helpers/review_status_helper.dart';
import 'common/quality_score_badge.dart';
import 'common/flags_list_widget.dart';

class ReviewDetailsDialog extends StatelessWidget {
  final dynamic review;

  const ReviewDetailsDialog({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    final data = _ReviewDetailsData(review);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.elevatedShadow,
        ),
        child: Column(
          children: [
            _Header(onClose: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                child: _DialogContent(
                  context: context,
                  data: data,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                   HEADER                                   */
/* -------------------------------------------------------------------------- */

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              size: 22,
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
                SizedBox(height: 2),
                Text(
                  'عرض وتحليل شامل للتقييم',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                MAIN CONTENT                                */
/* -------------------------------------------------------------------------- */

class _DialogContent extends StatelessWidget {
  final BuildContext context;
  final _ReviewDetailsData data;

  const _DialogContent({
    required this.context,
    required this.data,
  });

  @override
  Widget build(BuildContext _) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.status.isRejected) ...[
          RejectionCard(
            status: data.status,
            reason: data.rejectionReason,
          ),
          const SizedBox(height: 24),
        ],

        _Section(
          title: 'نص التقييم',
          icon: Icons.chat_bubble_outline_rounded,
          child: _TextCard(data.content),
        ),

        const SizedBox(height: 28),

        if (data.hasAIInsights) ...[
          _Section(
            title: 'تحليل الذكاء الاصطناعي',
            icon: Icons.auto_awesome_rounded,
            child: Column(
              children: [
                if (data.summary != null)
                  _InsightCard(
                    title: 'الملخص الذكي',
                    content: data.summary!,
                    icon: Icons.summarize_rounded,
                    color: AppColors.info,
                  ),
                if (data.insights != null)
                  ...data.insights!.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _InsightCard(
                        title: 'رؤية تحليلية',
                        content: e.toString(),
                        icon: Icons.lightbulb_outline_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],

        if (data.suggestedReply != null) ...[
          _Section(
            title: 'الرد المقترح',
            icon: Icons.reply_rounded,
            child: _SuggestedReplyCard(
              reply: data.suggestedReply!,
            ),
          ),
          const SizedBox(height: 28),
        ],

        _Section(
          title: 'تحليل الجودة',
          icon: Icons.verified_user_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.qualityScore != null)
                QualityScoreBadge(qualityScore: data.qualityScore!),
              if (data.flags.isNotEmpty) ...[
                const SizedBox(height: 16),
                FlagsListWidget(
                  flags: data.flags,
                  compact: false,
                  showDescriptions: true,
                ),
              ],
              if (data.hasWarnings) ...[
                const SizedBox(height: 16),
                WarningBox(
                  isProfane: data.isProfane,
                  isSuspicious: data.isSuspicious,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 28),

        _Section(
          title: 'معلومات المقيم',
          icon: Icons.person_outline_rounded,
          child: InfoGrid(data),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                UI WIDGETS                                  */
/* -------------------------------------------------------------------------- */

class RejectionCard extends StatelessWidget {
  final ReviewStatus status;
  final dynamic reason;

  const RejectionCard({
    super.key,
    required this.status,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final color = ReviewStatusHelper.getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
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
                  ),
                ),
                Text(
                  ReviewStatusHelper.getRejectionReasonArabic(reason),
                  style: TextStyle(color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WarningBox extends StatelessWidget {
  final bool isProfane;
  final bool isSuspicious;

  const WarningBox({
    super.key,
    required this.isProfane,
    required this.isSuspicious,
  });

  @override
  Widget build(BuildContext context) {
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
            _warningRow(
              Icons.warning_amber_rounded,
              'محتوى مسيء',
              'يحتوي على ألفاظ غير لائقة',
              AppColors.error,
            ),
          if (isSuspicious)
            _warningRow(
              Icons.report_problem_rounded,
              'نشاط مشبوه',
              'قد يكون تقييم غير حقيقي',
              AppColors.warning,
            ),
        ],
      ),
    );
  }

  Widget _warningRow(
    IconData icon,
    String title,
    String desc,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color)),
                Text(desc, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoGrid extends StatelessWidget {
  final _ReviewDetailsData data;

  const InfoGrid(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: [
        _item('البريد', data.email, Icons.email_outlined),
        _item('التاريخ', data.date, Icons.calendar_today_outlined),
        _item('التقييم', '${data.stars} نجوم', Icons.star_outline),
        _item('المشاعر', data.sentiment.toString(),
            Icons.sentiment_satisfied_alt),
        _item('الفئة', data.category.toString(), Icons.category_outlined),
      ],
    );
  }

  Widget _item(String label, String value, IconData icon) {
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
                Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                DATA MODEL                                  */
/* -------------------------------------------------------------------------- */

class _ReviewDetailsData {
  final dynamic raw;

  _ReviewDetailsData(this.raw);

  String get content =>
      raw['processing']?['concatenated_text'] ?? 'لا يوجد محتوى';

  String get email => raw['email'] ?? 'مجهول';

  String get date =>
      raw['created_at']?.toString().split('T').first ?? '';

  int get stars => raw['source']?['rating'] ?? raw['stars'] ?? 0;

  dynamic get sentiment =>
      raw['analysis']?['sentiment'] ?? raw['overall_sentiment'] ?? 'محايد';

  dynamic get category => raw['analysis']?['category'] ?? 'عام';

  ReviewStatus get status =>
      ReviewStatus.fromString(raw['status'] ?? 'processing');

  dynamic get rejectionReason => raw['rejection_reason'];

  double? get qualityScore =>
      raw['analysis']?['quality']?['quality_score'];

  bool get isProfane => raw['processing']?['is_profane'] ?? false;

  bool get isSuspicious =>
      raw['analysis']?['quality']?['is_suspicious'] ?? false;

  List<QualityFlag> get flags =>
      QualityFlag.parseList(raw['analysis']?['quality']?['flags']);

  bool get hasWarnings => isProfane || isSuspicious;

  String? get summary => raw['generated_content']?['summary'];

  List? get insights => raw['generated_content']?['actionable_insights'];

  String? get suggestedReply =>
      raw['generated_content']?['suggested_reply'];

  bool get hasAIInsights =>
      summary != null || (insights != null && insights!.isNotEmpty);
}

/* -------------------------------------------------------------------------- */
/*                                HELPERS                                     */
/* -------------------------------------------------------------------------- */

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
        child,
      ],
    );
  }
}

class _TextCard extends StatelessWidget {
  final String text;

  const _TextCard(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(height: 1.6),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _InsightCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(height: 1.6)),
        ],
      ),
    );
  }
}

class _SuggestedReplyCard extends StatelessWidget {
  final String reply;

  const _SuggestedReplyCard({required this.reply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(reply, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reply));
              AppSnackbar.showSuccess(context, 'تم نسخ الرد');
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('نسخ الرد'),
          ),
        ],
      ),
    );
  }
}
