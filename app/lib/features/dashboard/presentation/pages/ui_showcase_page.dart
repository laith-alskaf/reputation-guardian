import 'package:flutter/material.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/app_animations.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/theme/app_theme.dart';

/// Demo page showing all new UI components
class UIShowcasePage extends StatelessWidget {
  const UIShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UI Showcase')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Snackbars Section
          _buildSection(context, 'Snackbars', [
            ElevatedButton(
              onPressed: () =>
                  AppSnackbar.showSuccess(context, 'تم الحفظ بنجاح'),
              child: const Text('Success Snackbar'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => AppSnackbar.showError(
                context,
                'حدث خطأ في الاتصال',
                actionLabel: 'إعادة',
                onAction: () {},
              ),
              child: const Text('Error Snackbar'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  AppSnackbar.showWarning(context, 'تحذير: البيانات قديمة'),
              child: const Text('Warning Snackbar'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => AppSnackbar.showInfo(
                context,
                'معلومة: يمكنك تحديث البيانات الآن',
              ),
              child: const Text('Info Snackbar'),
            ),
          ]),

          const SizedBox(height: 24),

          // Animations Section
          _buildSection(context, 'Animations', [
            AppAnimations.fadeSlideIn(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.cardShadow,
                ),
                child: const Center(
                  child: Text(
                    'Fade + Slide Animation',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppAnimations.scaleIn(
              delay: const Duration(milliseconds: 200),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.successGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.elevatedShadow,
                ),
                child: const Center(
                  child: Text(
                    'Scale Animation',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // Loading States Section
          _buildSection(context, 'Loading States', [
            AppLoading.shimmerCard(height: 80),
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: AppLoading.inline(message: 'جاري التحميل...'),
            ),
          ]),

          const SizedBox(height: 24),

          // Empty States Section
          _buildSection(context, 'Empty States', [
            SizedBox(height: 200, child: AppEmptyState.noReviews()),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
