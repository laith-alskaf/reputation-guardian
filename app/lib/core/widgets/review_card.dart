import 'package:flutter/material.dart';
import 'package:reputation_guardian/core/theme/app_theme.dart';
import 'package:reputation_guardian/core/utils/responsive.dart';

class ReviewCard extends StatelessWidget {
  final String rating;
  final String sentiment;
  final String category;
  final String text;
  final String date;
  final String? email;
  final VoidCallback? onTap;

  const ReviewCard({
    super.key,
    required this.rating,
    required this.sentiment,
    required this.category,
    required this.text,
    required this.date,
    this.email,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sentimentColor = _getSentimentColor(sentiment);

    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveSpacing.medium(context)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Stars
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < int.parse(rating)
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.warning,
                        size: 18,
                      );
                    }),
                  ),
                  const Spacer(),
                  // Sentiment Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sentimentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sentimentColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      sentiment,
                      style: TextStyle(
                        color: sentimentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveSpacing.small(context)),

              // Text Preview
              Text(
                text.length > 150 ? '${text.substring(0, 150)}...' : text,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveSpacing.small(context)),

              // Footer
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              if (email != null) ...[
                SizedBox(height: ResponsiveSpacing.small(context)),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      email!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'إيجابي':
      case 'positive':
        return AppColors.positive;
      case 'سلبي':
      case 'negative':
        return AppColors.negative;
      default:
        return AppColors.neutralSentiment;
    }
  }
}
