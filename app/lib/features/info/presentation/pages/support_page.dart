import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_animations.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/utils/responsive.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'laithalskaf@gmail.com',
      query: 'subject=حارس السمعة - استفسار',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+963982055788');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/963982055788?text=مرحباً، لدي استفسار حول تطبيق حارس السمعة',
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        AppSnackbar.showError(context, 'تعذر فتح WhatsApp');
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackbar.showSuccess(context, 'تم نسخ $label');
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'المساعدة والدعم',
      showBackButton: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Header
            AppAnimations.scaleIn(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.elevatedShadow,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.support_agent,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'نحن هنا للمساعدة',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تواصل معنا في أي وقت',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Contact Developer Card
            AppAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 100),
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
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المطور',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'المهندس ليث السكاف',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'طرق التواصل:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _buildContactItem(
                      context: context,
                      icon: Icons.email,
                      title: 'البريد الإلكتروني',
                      value: 'laithalskaf@gmail.com',
                      color: AppColors.primary,
                      onTap: _launchEmail,
                      onCopy: () => _copyToClipboard(
                        context,
                        'laithalskaf@gmail.com',
                        'البريد الإلكتروني',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    _buildContactItem(
                      context: context,
                      icon: Icons.phone,
                      title: 'رقم الهاتف',
                      value: '+963 982 055 788',
                      color: AppColors.positive,
                      onTap: _launchPhone,
                      onCopy: () => _copyToClipboard(
                        context,
                        '+963982055788',
                        'رقم الهاتف',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            AppAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'إجراءات سريعة:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp Button
                  _buildActionButton(
                    context: context,
                    icon: Icons.chat,
                    title: 'تواصل عبر WhatsApp',
                    subtitle: 'رد سريع ومباشر',
                    gradient: LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    ),
                    onTap: () => _launchWhatsApp(context),
                  ),
                  const SizedBox(height: 12),

                  // Email Button
                  _buildActionButton(
                    context: context,
                    icon: Icons.mail_outline,
                    title: 'إرسال بريد إلكتروني',
                    subtitle: 'للاستفسارات التفصيلية',
                    gradient: AppColors.primaryGradient,
                    onTap: _launchEmail,
                  ),
                  const SizedBox(height: 12),

                  // Call Button
                  _buildActionButton(
                    context: context,
                    icon: Icons.phone_in_talk,
                    title: 'اتصال هاتفي',
                    subtitle: 'للحالات العاجلة',
                    gradient: AppColors.successGradient,
                    onTap: _launchPhone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // FAQ Section
            AppAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: AppColors.info),
                        const SizedBox(width: 12),
                        const Text(
                          'نصيحة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'للحصول على أفضل خدمة، يرجى تضمين معلومات واضحة عن المشكلة أو الاستفسار عند التواصل معنا.',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onCopy,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: onCopy,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
