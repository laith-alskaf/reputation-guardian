import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/enums/review_status_enum.dart';
import '../../domain/enums/quality_flag_enum.dart';
import '../../domain/helpers/review_status_helper.dart';
import 'common/quality_score_badge.dart';
import 'common/flags_list_widget.dart';

/// Enhanced review card with full quality analysis support
class ReviewCard extends StatelessWidget {
  final dynamic review;
  final String type;
  final VoidCallback onTap;
  final Color Function(String) getSentimentColor;
  final IconData Function(String) getSentimentIcon;
  final String Function(String) getSentimentLabel;

  const ReviewCard({
    super.key,
    required this.review,
    required this.type,
    required this.onTap,
    required this.getSentimentColor,
    required this.getSentimentIcon,
    required this.getSentimentLabel,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final formatter = DateFormat('d MMMM yyyy، h:mm a', 'ar');
      return formatter.format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: AppColors.warning,
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract data
    final sentiment = review['analysis']?['sentiment'] ?? 'غير محدد';
    final rating = review['source']?['rating'] ?? 0;
    final reviewText = review['processing']?['concatenated_text'] ?? '';
    final date = review['created_at'] ?? review['timestamp'] ?? '';
    final qualityScore = review['analysis']?['quality']?['quality_score'];
    final isProfane = review['processing']?['is_profane'] ?? false;
    final isSuspicious =
        review['analysis']?['quality']?['is_suspicious'] ?? false;
    final status = ReviewStatus.fromString(review['status'] ?? 'processing');
    final rejectionReason = review['rejection_reason'];

    // Parse flags
    final flagsList = review['analysis']?['quality']?['flags'];
    final flags = QualityFlag.parseList(flagsList);

    final sentimentColor = getSentimentColor(sentiment);
    final sentimentIcon = getSentimentIcon(sentiment);
    final sentimentLabel = getSentimentLabel(sentiment);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Sentiment Aura (Soft Glow)
          BoxShadow(
            color: sentimentColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          ...AppColors.cardShadow,
        ],
        border: Border.all(color: sentimentColor.withOpacity(0.15), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle Background Icon
          Positioned(
            right: -20,
            top: -10,
            child: Icon(
              sentimentIcon,
              size: 100,
              color: sentimentColor.withOpacity(0.03),
            ),
          ),

          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Sentiment + Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: sentimentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              sentimentIcon,
                              color: sentimentColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sentimentLabel,
                                style: TextStyle(
                                  color: sentimentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (status != ReviewStatus.processed)
                                Text(
                                  status.shortLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: ReviewStatusHelper.getStatusColor(
                                      status,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      _buildStars(rating),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Review text with improved typography
                  if (reviewText.isNotEmpty)
                    Text(
                      reviewText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Footer: Date + Quality Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.textSecondary.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (qualityScore != null)
                        QualityScoreBadge(
                          qualityScore: qualityScore,
                          iconSize: 14,
                          fontSize: 12,
                        ),
                    ],
                  ),

                  // Compact Flags (Rejection context)
                  if (status.isRejected &&
                      (flags.isNotEmpty || rejectionReason != null)) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                    if (flags.isNotEmpty)
                      FlagsListWidget(flags: flags, compact: true, maxFlags: 3),

                    if (rejectionReason != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ReviewStatusHelper.getStatusBackgroundColor(
                            status,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 13,
                              color: ReviewStatusHelper.getStatusColor(status),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ReviewStatusHelper.getRejectionReasonArabic(
                                rejectionReason,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: ReviewStatusHelper.getStatusColor(
                                  status,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Top Left Badges (Profanity/Suspicious)
          if (status.isRejected && isProfane)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.error, Color(0xFFFF6B6B)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'محتوى مسيئ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isSuspicious)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.report_problem_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'مشبوه',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
