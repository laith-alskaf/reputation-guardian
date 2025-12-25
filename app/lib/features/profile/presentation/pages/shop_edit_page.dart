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
              // Shop Info Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
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
                              Icons.store_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'بيانات المتجر',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Shop Name Field
                      TextFormField(
                        controller: _shopNameController,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'اسم المتجر',
                          labelStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                          prefixIcon: const Icon(
                            Icons.store_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: AppColors.background.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال اسم المتجر';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Shop Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedShopType,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          labelText: 'نوع المتجر',
                          labelStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                          prefixIcon: const Icon(
                            Icons.category_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: AppColors.background.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
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
                      ),

                      if (_selectedShopType == 'أخرى') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _shopTypeController,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'حدد نوع المتجر',
                            labelStyle: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                            prefixIcon: const Icon(
                              Icons.edit_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors.background.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.primary.withOpacity(0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.primary.withOpacity(0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: ResponsiveSpacing.medium(context)),

              // Info Card
              Container(
                padding: EdgeInsets.all(ResponsiveSpacing.medium(context)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
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

              SizedBox(height: ResponsiveSpacing.large(context)),

              // Save Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.elevatedShadow,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                      : const Text(
                          'حفظ التغييرات',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
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
      // Prepare shop data
      final shopName = _shopNameController.text.trim();
      final shopType = _selectedShopType == 'أخرى'
          ? _shopTypeController.text.trim()
          : _selectedShopType;

      // TODO: Implement actual API call through a use case or repository
      // For now, this is a placeholder that simulates the API call
      // In a real implementation, you would:
      // 1. Create a UpdateShopInfoUseCase
      // 2. Call it with the shop data
      // 3. Update the DashboardBloc state with the new data

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
