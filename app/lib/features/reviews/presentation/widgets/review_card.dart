import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/enums/review_status_enum.dart';
import '../../domain/enums/quality_flag_enum.dart';
import '../../domain/helpers/review_status_helper.dart';
import '../../domain/helpers/quality_flag_helper.dart';
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
    final mostCriticalFlag = QualityFlagHelper.getMostCritical(flags);

    final sentimentColor = getSentimentColor(sentiment);
    final sentimentIcon = getSentimentIcon(sentiment);
    final sentimentLabel = getSentimentLabel(sentiment);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Status Badge + Sentiment + Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Sentiment Info
                      Expanded(
                        child: Row(
                          children: [
                            // Status badge (if not processed)
                            if (status != ReviewStatus.processed) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      ReviewStatusHelper.getStatusBackgroundColor(
                                        status,
                                      ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        ReviewStatusHelper.getStatusBorderColor(
                                          status,
                                        ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      ReviewStatusHelper.getStatusIcon(status),
                                      size: 12,
                                      color: ReviewStatusHelper.getStatusColor(
                                        status,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status.shortLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            ReviewStatusHelper.getStatusColor(
                                              status,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Sentiment
                            Icon(
                              sentimentIcon,
                              color: sentimentColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                sentimentLabel,
                                style: TextStyle(
                                  color: sentimentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right: Stars
                      _buildStars(rating),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Review text
                  if (reviewText.isNotEmpty)
                    Text(
                      reviewText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Footer: Date + Quality Score + Flags
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Date
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _formatDate(date),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quality score badge
                      if (qualityScore != null)
                        QualityScoreBadge(
                          qualityScore: qualityScore,
                          iconSize: 14,
                          fontSize: 12,
                        ),
                    ],
                  ),

                  // Flags preview (compact)
                  if (flags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    FlagsListWidget(flags: flags, compact: true, maxFlags: 3),
                  ],

                  // Rejection reason (if rejected)
                  if (status.isRejected && rejectionReason != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ReviewStatusHelper.getStatusBackgroundColor(
                          status,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ReviewStatusHelper.getStatusBorderColor(
                            status,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: ReviewStatusHelper.getStatusColor(status),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ReviewStatusHelper.getRejectionReasonArabic(
                                rejectionReason,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: ReviewStatusHelper.getStatusColor(
                                  status,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

          // Profanity warning ribbon (top right)
          if (isProfane)
            Positioned(
              top: 0,
              right: 0,
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
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'محتوى غير لائق',
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

          // Critical flag ribbon (top left) - only if not profane and has critical flag
          if (!isProfane &&
              mostCriticalFlag != null &&
              mostCriticalFlag.isSevere)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      mostCriticalFlag.color,
                      mostCriticalFlag.color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(mostCriticalFlag.icon, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      mostCriticalFlag.arabicLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Suspicious indicator (bottom right corner)
          if (isSuspicious && !isProfane)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.report_problem, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'مشبوه',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
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
