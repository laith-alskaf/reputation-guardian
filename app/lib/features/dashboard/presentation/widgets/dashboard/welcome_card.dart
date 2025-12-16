import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/cards/section_card.dart';

/// Welcome card widget for dashboard
class WelcomeCard extends StatelessWidget {
  final String shopName;

  const WelcomeCard({super.key, required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.medium(context),
      ),
      child: SectionCard(
        title: 'مرحباً بك في حارس السمعة',
        icon: Icons.shield,
        iconColor: AppColors.primary,
        children: [
          Text(
            'إدارة سمعة $shopName',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'تابع تقييمات عملائك وحسّن خدماتك',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
