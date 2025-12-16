import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'الإعدادات',
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader(context, 'الحساب'),
          _buildSettingTile(
            context,
            icon: Icons.person,
            title: 'الملف الشخصي',
            subtitle: 'عرض وتعديل معلومات الحساب',
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.store,
            title: 'معلومات المتجر',
            subtitle: 'تعديل بيانات المتجر',
            onTap: () {},
          ),

          SizedBox(height: ResponsiveSpacing.large(context)),

          // Notifications Section
          _buildSectionHeader(context, 'الإشعارات'),
          _buildSettingTile(
            context,
            icon: Icons.notifications,
            title: 'إشعارات Push',
            subtitle: 'استلام إشعارات التقييمات الجديدة',
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: AppColors.primary,
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.telegram,
            title: 'ربط Telegram',
            subtitle: 'استلام التنبيهات عبر تيليجرام',
            onTap: () {},
          ),

          SizedBox(height: ResponsiveSpacing.large(context)),

          // App Settings
          _buildSectionHeader(context, 'إعدادات التطبيق'),
          _buildSettingTile(
            context,
            icon: Icons.dark_mode,
            title: 'المظهر الداكن',
            subtitle: 'التبديل بين الوضع الفاتح والداكن',
            trailing: Switch(
              value: false,
              onChanged: (value) {},
              activeColor: AppColors.primary,
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.language,
            title: 'اللغة',
            subtitle: 'العربية',
            onTap: () {},
          ),

          SizedBox(height: ResponsiveSpacing.large(context)),

          // Other
          _buildSectionHeader(context, 'أخرى'),
          _buildSettingTile(
            context,
            icon: Icons.help_outline,
            title: 'المساعدة والدعم',
            subtitle: 'الحصول على مساعدة',
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.info_outline,
            title: 'حول التطبيق',
            subtitle: 'الإصدار 1.0.0',
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            subtitle: 'الخروج من الحساب',
            onTap: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        // Logout
                        final authLocalDataSource =
                            getIt<AuthLocalDataSource>();
                        await authLocalDataSource.deleteToken();
                        // Navigate to login
                        if (context.mounted) {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                      child: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            textColor: AppColors.error,
          ),

          SizedBox(height: ResponsiveSpacing.xlarge(context)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveSpacing.small(context),
        top: ResponsiveSpacing.small(context),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? textColor,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveSpacing.small(context)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (textColor ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: textColor ?? AppColors.primary),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        ),
        subtitle: Text(subtitle),
        trailing:
            trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
        onTap: onTap,
      ),
    );
  }
}
