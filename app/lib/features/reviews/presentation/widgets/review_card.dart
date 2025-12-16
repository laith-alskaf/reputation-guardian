import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

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
      // Format: 15 ديسمبر 2024، 10:30 م
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
    // Extract data based on review structure
    final sentiment = review['analysis']?['sentiment'] ?? 'غير محدد';
    final rating = review['source']?['rating'] ?? 0;
    final reviewText = review['processing']?['concatenated_text'] ?? '';
    final date = review['created_at'] ?? review['timestamp'] ?? '';
    final qualityScore = review['analysis']?['quality']?['quality_score'];
    final isProfane = review['processing']?['is_profane'] ?? false;
    final flags = review['analysis']?['quality']?['flags'];
    final hasFlags = flags != null && (flags as List).isNotEmpty;

    final sentimentColor = getSentimentColor(sentiment);
    final sentimentIcon = getSentimentIcon(sentiment);
    final sentimentLabel = getSentimentLabel(sentiment);

    // Get flag label for ribbon
    String? flagLabel;
    if (hasFlags) {
      final firstFlag = flags.first.toString();
      switch (firstFlag) {
        case 'high_toxicity':
          flagLabel = 'سمية عالية';
          break;
        case 'spam':
          flagLabel = 'spam';
          break;
        case 'low_quality':
          flagLabel = 'جودة منخفضة';
          break;
        case 'irrelevant':
          flagLabel = 'غير ذي صلة';
          break;
        default:
          flagLabel = firstFlag;
      }
    }

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
                  // Header: Sentiment + Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sentiment badge
                      Row(
                        children: [
                          Icon(sentimentIcon, color: sentimentColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            sentimentLabel,
                            style: TextStyle(
                              color: sentimentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      // Stars rating
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
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Footer: Date + Quality Score
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
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Quality score badge
                      if (qualityScore != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: qualityScore >= 0.7
                                ? LinearGradient(
                                    colors: [
                                      AppColors.success.withOpacity(0.2),
                                      AppColors.success.withOpacity(0.1),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      AppColors.warning.withOpacity(0.2),
                                      AppColors.warning.withOpacity(0.1),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: qualityScore >= 0.7
                                  ? AppColors.success.withOpacity(0.3)
                                  : AppColors.warning.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: qualityScore >= 0.7
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(qualityScore * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: qualityScore >= 0.7
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
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

          // Flags ribbon (top left)
          if (hasFlags && !isProfane && flagLabel != null)
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
                    colors: [Color(0xFFFF9800), Color(0xFFFFA726)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      flagLabel,
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
        ],
      ),
    );
  }
}
