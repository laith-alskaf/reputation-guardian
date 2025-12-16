import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/app_animations.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _shopNameController = TextEditingController();
  String? _selectedShopType;
  bool _obscurePassword = true;
  late AnimationController _animationController;

  final List<String> _shopTypes = [
    'مطعم',
    'مقهى',
    'محل ملابس',
    'صيدلية',
    'سوبر ماركت',
    'متجر إلكترونيات',
    'مكتبة',
    'محل تجميل',
    'صالة رياضية',
    'مدرسة/روضة',
    'مستشفى/عيادة',
    'محطة وقود',
    'متجر أجهزة',
    'محل ألعاب',
    'مكتب سياحي',
    'محل هدايا',
    'مغسلة ملابس',
    'متجر هواتف',
    'محل أثاث',
    'آخر',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (_selectedShopType == null) {
        AppSnackbar.showWarning(context, 'يرجى اختيار نوع المتجر');
        return;
      }

      context.read<AuthBloc>().add(
        RegisterRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          shopName: _shopNameController.text.trim(),
          shopType: _selectedShopType!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppSnackbar.showError(context, state.message);
          } else if (state is Authenticated) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  const Color(0xFF7C3AED),
                  AppColors.primary.withOpacity(0.8),
                  AppColors.primary,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom AppBar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                            ),
                            onPressed: isLoading
                                ? null
                                : () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo
                            AppAnimations.scaleIn(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.store,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            AppAnimations.fadeSlideIn(
                              delay: const Duration(milliseconds: 100),
                              child: Text(
                                'انضم إلينا',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Form Card
                            AppAnimations.fadeSlideIn(
                              delay: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Email Field
                                    CustomTextField(
                                      controller: _emailController,
                                      label: 'البريد الإلكتروني',
                                      hint: 'example@email.com',
                                      prefixIcon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: Validators.validateEmail,
                                      enabled: !isLoading,
                                    ),
                                    const SizedBox(height: 16),

                                    // Password Field
                                    CustomTextField(
                                      controller: _passwordController,
                                      label: 'كلمة المرور',
                                      hint: '••••••••',
                                      prefixIcon: Icons.lock,
                                      obscureText: _obscurePassword,
                                      validator: Validators.validatePassword,
                                      enabled: !isLoading,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Shop Name Field
                                    CustomTextField(
                                      controller: _shopNameController,
                                      label: 'اسم المتجر',
                                      hint: 'اسم متجرك أو عملك',
                                      prefixIcon: Icons.store,
                                      validator: (value) =>
                                          Validators.validateMinLength(
                                            value,
                                            2,
                                            'اسم المتجر',
                                          ),
                                      enabled: !isLoading,
                                    ),
                                    const SizedBox(height: 16),

                                    // Shop Type Dropdown
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'نوع المتجر',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.border,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: DropdownButtonFormField<String>(
                                            value: _selectedShopType,
                                            decoration: const InputDecoration(
                                              hintText: 'اختر نوع المتجر',
                                              prefixIcon: Icon(Icons.category),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                            ),
                                            items: _shopTypes.map((type) {
                                              return DropdownMenuItem(
                                                value: type,
                                                child: Text(
                                                  type,
                                                  textDirection:
                                                      TextDirection.rtl,
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: isLoading
                                                ? null
                                                : (value) {
                                                    setState(() {
                                                      _selectedShopType = value;
                                                    });
                                                  },
                                            validator: (value) {
                                              if (value == null) {
                                                return 'يرجى اختيار نوع المتجر';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Register Button
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: AppColors.elevatedShadow,
                                      ),
                                      child: CustomButton(
                                        text: 'إنشاء الحساب',
                                        onPressed: _handleRegister,
                                        isLoading: isLoading,
                                        icon: Icons.person_add,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Login Link
                            AppAnimations.fadeSlideIn(
                              delay: const Duration(milliseconds: 300),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'لديك حساب بالفعل؟',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            Navigator.of(context).pop();
                                          },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    child: const Text('تسجيل الدخول'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
