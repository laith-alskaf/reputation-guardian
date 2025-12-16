import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_animations.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/utils/responsive.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'حول التطبيق',
      showBackButton: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // App Logo
            AppAnimations.scaleIn(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.elevatedShadow,
                ),
                child: const Icon(Icons.shield, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),

            // App Name
            AppAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: const Text(
                'حارس السمعة',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            AppAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: const Text(
                'Reputation Guardian',
                style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            AppAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'الإصدار 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Description Card
            AppAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, AppColors.surface],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'نبذة عن التطبيق',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'حارس السمعة هو تطبيق ذكي متخصص في إدارة وتحليل تقييمات العملاء باستخدام تقنيات الذكاء الاصطناعي المتقدمة.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: AppColors.text,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'يساعدك التطبيق على:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem('تحليل مشاعر العملاء تلقائياً'),
                    _buildFeatureItem('الحصول على رؤى قابلة للتنفيذ'),
                    _buildFeatureItem('إنشاء ردود احترافية مقترحة'),
                    _buildFeatureItem('تصفية التقييمات منخفضة الجودة'),
                    _buildFeatureItem('تتبع أداء متجرك بشكل مستمر'),
                    _buildFeatureItem('استقبال إشعارات فورية عبر Telegram'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Features Grid
            AppAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 500),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.psychology,
                      title: 'ذكاء اصطناعي',
                      subtitle: 'تحليل متقدم',
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.speed,
                      title: 'سريع',
                      subtitle: 'نتائج فورية',
                      gradient: AppColors.successGradient,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            AppAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 600),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.security,
                      title: 'آمن',
                      subtitle: 'بيانات محمية',
                      gradient: AppColors.errorGradient,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.support_agent,
                      title: 'دعم 24/7',
                      subtitle: 'متواجدون دائماً',
                      gradient: LinearGradient(
                        colors: [
                          AppColors.warning,
                          AppColors.warning.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
