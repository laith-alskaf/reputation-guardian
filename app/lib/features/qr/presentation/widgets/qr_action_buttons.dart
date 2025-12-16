import 'package:flutter/material.dart';

class QRActionButtons extends StatelessWidget {
  final VoidCallback onDownload;
  final VoidCallback onShare;

  const QRActionButtons({
    super.key,
    required this.onDownload,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.download),
          label: const Text('تحميل'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share),
          label: const Text('مشاركة'),
        ),
      ],
    );
  }
}
