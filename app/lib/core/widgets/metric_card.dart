import 'package:flutter/material.dart';
import 'package:reputation_guardian/core/theme/app_theme.dart';

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final bool isFullWidth;

  const MetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isFullWidth
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (color ?? AppColors.primary).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color ?? AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color ?? AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (color ?? AppColors.primary).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color ?? AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color ?? AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}
