import 'package:flutter/material.dart';
import 'package:reputation_guardian/core/theme/app_theme.dart';

class SentimentBadge extends StatelessWidget {
  final String sentiment;
  final bool isSmall;

  const SentimentBadge({
    super.key,
    required this.sentiment,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String emoji;
    String text;

    switch (sentiment.toLowerCase()) {
      case 'إيجابي':
      case 'positive':
        color = AppColors.positive;
        emoji = '🟢';
        text = 'إيجابي';
        break;
      case 'سلبي':
      case 'negative':
        color = AppColors.negative;
        emoji = '🔴';
        text = 'سلبي';
        break;
      default:
        color = AppColors.neutralSentiment;
        emoji = '🟡';
        text = 'محايد';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: isSmall ? 12 : 14),
          ),
          SizedBox(width: isSmall ? 4 : 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isSmall ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
