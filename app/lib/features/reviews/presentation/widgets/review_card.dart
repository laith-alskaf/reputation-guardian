import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Review card widget for displaying a single review
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
    final sentiment = review['sentiment'] ?? 'neutral';
    final stars = (review['stars'] as num?)?.toInt() ?? 0;
    final customerName = review['customer_name'] ?? 'عميل غير معروف';
    final reviewText = review['review_text'] ?? '';
    final date = review['created_at'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Customer name, stars, sentiment
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStars(stars),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: getSentimentColor(
                        sentiment,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getSentimentIcon(sentiment),
                          size: 16,
                          color: getSentimentColor(sentiment),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          getSentimentLabel(sentiment),
                          style: TextStyle(
                            color: getSentimentColor(sentiment),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

              const SizedBox(height: 12),

              // Footer: Date and type badges
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (type == 'all' && review.containsKey('sentiment'))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sentiment,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
