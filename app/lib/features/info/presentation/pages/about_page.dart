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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  // gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(3, 3),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/icons/icon.png',
                  width: 80,
                  height: 80,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // App Name
            AppAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: Column(
                children: [
                  Text(
                    "ReviewIQ",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reputation Guardian',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withOpacity(0.8),
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            AppAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'الإصدار 1.0.0',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Description Card
            AppAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.dashboard_customize_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'نبذة عن النظام',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'حارس السمعة هو منصة احترافية متكاملة تهدف إلى مساعدة أصحاب الأعمال على إدارة سمعتهم الرقمية بذكاء. باستخدام تقنيات الذكاء الاصطناعي، نقوم بتحليل التقييمات وتصفيتها لضمان حصولك على رؤى دقيقة وحلول فورية.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.text,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'المميزات الرئيسية:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem('تحليل المشاعر بدقة عالية باستخدام AI'),
                    _buildFeatureItem(
                      'نظام ذكي لاكتشاف وتصفية التقييمات السلبية المضللة',
                    ),
                    _buildFeatureItem('لوحة بيانات تحليلية فورية وشاملة'),
                    _buildFeatureItem(
                      'تنبيهات فورية عبر Telegram لسرعة المتابعة',
                    ),
                    _buildFeatureItem(
                      'اقتراح ردود احترافية لتحسين تجربة العميل',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Features Grid
            AppAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 500),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildStatCard(
                    icon: Icons.psychology_rounded,
                    title: 'ذكاء اصطناعي',
                    subtitle: 'تحليل لغوي متقدم',
                    gradient: AppColors.primaryGradient,
                  ),
                  _buildStatCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'أتمتة ذكية',
                    subtitle: 'ردود فورية مقترحة',
                    gradient: AppColors.successGradient,
                  ),
                  _buildStatCard(
                    icon: Icons.security_rounded,
                    title: 'حماية رقمية',
                    subtitle: 'تصفية للمحتوى الضار',
                    gradient: AppColors.errorGradient,
                  ),
                  _buildStatCard(
                    icon: Icons.analytics_rounded,
                    title: 'تحليلات',
                    subtitle: 'رؤى دقيقة للأداء',
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.text.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
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
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.85),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
