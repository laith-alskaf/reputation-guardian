import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/validators.dart';
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

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _shopNameController = TextEditingController();
  String? _selectedShopType;
  bool _obscurePassword = true;

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (_selectedShopType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار نوع المتجر'),
            backgroundColor: Colors.red,
          ),
        );
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
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is Authenticated) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            _obscurePassword = !_obscurePassword;
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
                      validator: (value) => Validators.validateMinLength(
                        value,
                        2,
                        'اسم المتجر',
                      ),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Shop Type Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نوع المتجر',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedShopType,
                          decoration: const InputDecoration(
                            hintText: 'اختر نوع المتجر',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: _shopTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child:
                                  Text(type, textDirection: TextDirection.rtl),
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
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Register Button
                    CustomButton(
                      text: 'إنشاء الحساب',
                      onPressed: _handleRegister,
                      isLoading: isLoading,
                      icon: Icons.person_add,
                    ),
                    const SizedBox(height: 16),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('لديك حساب بالفعل؟'),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          child: const Text('تسجيل الدخول'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
