import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class QRDisplayWidget extends StatelessWidget {
  final String qrCode;

  const QRDisplayWidget({super.key, required this.qrCode});

  @override
  Widget build(BuildContext context) {
    try {
      // Try to decode as base64
      final bytes = base64Decode(qrCode);
      return Image.memory(
        bytes,
        width: 200,
        height: 200,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } catch (e) {
      // If not base64, try as URL
      if (qrCode.startsWith('http')) {
        return Image.network(
          qrCode,
          width: 200,
          height: 200,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        );
      }
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 200,
      height: 200,
      color: AppColors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            'خطأ في عرض QR',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
