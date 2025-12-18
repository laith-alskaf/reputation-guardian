import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/helpers/quality_score_helper.dart';

/// A badge widget that displays the quality score with color coding
class QualityScoreBadge extends StatelessWidget {
  final double qualityScore;
  final double iconSize;
  final double fontSize;
  final bool showLabel;
  final bool showPercentage;

  const QualityScoreBadge({
    super.key,
    required this.qualityScore,
    this.iconSize = 16,
    this.fontSize = 12,
    this.showLabel = false,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = QualityScoreHelper.getQualityColor(qualityScore);
    final percentage = QualityScoreHelper.getQualityPercentage(qualityScore);
    final icon = QualityScoreHelper.getQualityIcon(qualityScore);
    final label = QualityScoreHelper.getQualityLabel(qualityScore);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: QualityScoreHelper.getQualityGradient(qualityScore),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: QualityScoreHelper.getQualityBorderColor(qualityScore),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 4),
          if (showPercentage)
            Text(
              percentage,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: fontSize - 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A larger quality score display widget for dialogs
class QualityScoreCard extends StatelessWidget {
  final double qualityScore;

  const QualityScoreCard({super.key, required this.qualityScore});

  @override
  Widget build(BuildContext context) {
    final color = QualityScoreHelper.getQualityColor(qualityScore);
    final percentage = QualityScoreHelper.getQualityPercentage(qualityScore);
    final label = QualityScoreHelper.getQualityLabel(qualityScore);
    final description = QualityScoreHelper.getQualityDescription(qualityScore);
    final emoji = QualityScoreHelper.getQualityEmoji(qualityScore);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: QualityScoreHelper.getQualityGradient(qualityScore),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: QualityScoreHelper.getQualityBorderColor(qualityScore),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                percentage,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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
