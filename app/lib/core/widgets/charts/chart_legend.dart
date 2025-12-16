import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable chart legend component
///
/// Usage:
/// ```dart
/// ChartLegend(
///   items: [
///     LegendItem(label: 'إيجابي', color: AppColors.positive, value: '45'),
///     LegendItem(label: 'محايد', color: AppColors.warning, value: '30'),
///     LegendItem(label: 'سلبي', color: AppColors.negative, value: '25'),
///   ],
/// )
/// ```
class ChartLegend extends StatelessWidget {
  final List<LegendItem> items;
  final Axis direction;

  const ChartLegend({
    super.key,
    required this.items,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.horizontal) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) => _buildLegendItem(item)).toList(),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => _buildLegendItem(item)).toList(),
      );
    }
  }

  Widget _buildLegendItem(LegendItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (item.value != null)
                Text(
                  item.value!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class LegendItem {
  final String label;
  final Color color;
  final String? value;

  const LegendItem({required this.label, required this.color, this.value});
}
