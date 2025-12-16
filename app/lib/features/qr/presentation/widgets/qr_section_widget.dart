import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'qr_display_widget.dart';
import 'qr_action_buttons.dart';

class QRSectionWidget extends StatelessWidget {
  final String qrCode;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  const QRSectionWidget({
    super.key,
    required this.qrCode,
    this.onDownload,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'رمز QR الخاص بك',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QRDisplayWidget(qrCode: qrCode),
                    const SizedBox(height: 16),
                    QRActionButtons(
                      onDownload: onDownload ?? () {},
                      onShare: onShare ?? () {},
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
}
