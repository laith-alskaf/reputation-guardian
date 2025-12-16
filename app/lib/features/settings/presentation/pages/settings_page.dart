import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_state.dart';
import '../../../profile/presentation/pages/profile_edit_page.dart';
import '../../../profile/presentation/pages/shop_edit_page.dart';
import '../../../info/presentation/pages/about_page.dart';
import '../../../info/presentation/pages/support_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    // TODO: Load from SharedPreferences
    setState(() {
      _isDarkMode = false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    // TODO: Save to SharedPreferences and apply theme
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'تم تفعيل الوضع الداكن' : 'تم تفعيل الوضع الفاتح',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditPage(),
                ),
              );
            },
          ),
          _buildSettingTile(
            context,
            icon: Icons.store,
            title: 'معلومات المتجر',
            subtitle: 'تعديل بيانات المتجر',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShopEditPage()),
              );
            },
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
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.telegram,
            title: 'ربط Telegram',
            subtitle: 'استلام التنبيهات عبر تيليجرام',
            onTap: () {
              _showTelegramDialog();
            },
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
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportPage()),
              );
            },
          ),
          _buildSettingTile(
            context,
            icon: Icons.info_outline,
            title: 'حول التطبيق',
            subtitle: 'الإصدار 1.0.0',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
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

  void _showTelegramDialog() async {
    // Check if already connected
    final telegramChatId = await _getTelegramChatId();

    if (telegramChatId != null && telegramChatId.isNotEmpty) {
      // Already connected - show disconnect option
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.telegram, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Telegram متصل'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 64, color: AppColors.positive),
              SizedBox(height: 16),
              Text(
                'حسابك مربوط بنجاح مع Telegram',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'ستصلك إشعارات فورية عند وصول تقييمات جديدة',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _disconnectTelegram();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('فك الربط'),
            ),
          ],
        ),
      );
    } else {
      // Not connected - show connect instructions
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.telegram, color: AppColors.primary),
              SizedBox(width: 8),
              Text('ربط Telegram'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'للحصول على إشعارات فورية عبر Telegram:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStep('1', 'اضغط على "فتح Telegram" أسفل'),
              _buildStep('2', 'اضغط على Start في البوت'),
              _buildStep('3', 'انتظر رسالة التأكيد'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم ربط حسابك تلقائياً',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _openTelegramBot();
              },
              icon: const Icon(Icons.telegram),
              label: const Text('فتح Telegram'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<String?> _getTelegramChatId() async {
    // TODO: Get from API/SharedPreferences
    return null;
  }

  Future<void> _openTelegramBot() async {
    try {
      const botUsername = 'LaithAlskafBot';

      // Get shop ID from dashboard state
      final dashboardState = context.read<DashboardBloc>().state;
      final shopId = dashboardState is DashboardLoaded
          ? dashboardState.dashboardData.shopInfo.shopId
          : '';

      final telegramUrl = Uri.parse('https://t.me/$botUsername?start=$shopId');

      await launchUrl(telegramUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _disconnectTelegram() async {
    // TODO: Call API to remove telegram_chat_id
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم فك ربط Telegram')));
  }

  static Widget _buildSectionHeader(BuildContext context, String title) {
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
