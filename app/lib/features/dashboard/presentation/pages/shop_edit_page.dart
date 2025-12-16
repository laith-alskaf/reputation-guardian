import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/responsive_scaffold.dart';

class ShopEditPage extends StatefulWidget {
  const ShopEditPage({super.key});

  @override
  State<ShopEditPage> createState() => _ShopEditPageState();
}

class _ShopEditPageState extends State<ShopEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopTypeController = TextEditingController();

  bool _isLoading = false;
  String _selectedShopType = 'محل ملابس';

  final List<String> _shopTypes = [
    'محل ملابس',
    'مطعم',
    'كافيه',
    'صيدلية',
    'محل إلكترونيات',
    'صالون تجميل',
    'محل أحذية',
    'محل إكسسوارات',
    'سوبر ماركت',
    'مخبز',
    'محل هدايا',
    'محل رياضة',
    'محل كتب',
    'محل عطور',
    'أخرى',
  ];

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'معلومات المتجر',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Shop Icon
              _buildShopIcon(),
              SizedBox(height: ResponsiveSpacing.large(context)),

              // Shop Info Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بيانات المتجر',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Shop Name Field
                      TextFormField(
                        controller: _shopNameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المتجر',
                          prefixIcon: Icon(Icons.store),
                          hintText: 'مثال: متجر الأناقة',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال اسم المتجر';
                          }
                          if (value.length < 2) {
                            return 'اسم المتجر يجب أن يكون حرفين على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Shop Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedShopType,
                        decoration: const InputDecoration(
                          labelText: 'نوع المتجر',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _shopTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedShopType = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء اختيار نوع المتجر';
                          }
                          return null;
                        },
                      ),

                      if (_selectedShopType == 'أخرى') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _shopTypeController,
                          decoration: const InputDecoration(
                            labelText: 'حدد نوع المتجر',
                            prefixIcon: Icon(Icons.edit),
                          ),
                          validator: (value) {
                            if (_selectedShopType == 'أخرى' &&
                                (value == null || value.isEmpty)) {
                              return 'الرجاء تحديد نوع المتجر';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: ResponsiveSpacing.medium(context)),

              // Info Card
              Card(
                color: AppColors.primary.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'معلومات متجرك تساعد عملاءك في التعرف عليك بشكل أفضل',
                          style: TextStyle(
                            color: AppColors.primary.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: ResponsiveSpacing.large(context)),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('حفظ التغييرات'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopIcon() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.store, size: 60, color: AppColors.primary),
      ),
    );
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to save shop info
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ معلومات المتجر بنجاح'),
            backgroundColor: AppColors.positive,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
