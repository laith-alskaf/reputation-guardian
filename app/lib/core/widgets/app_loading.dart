import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Loading widgets and states
class AppLoading {
  /// Full screen loading overlay
  static Widget fullScreen({String? message}) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14, color: AppColors.text),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Inline loading indicator
  static Widget inline({String? message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Small loading spinner
  static Widget small() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  /// Card skeleton for loading state
  static Widget cardSkeleton({double height = 100, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// List skeleton
  static Widget listSkeleton({int itemCount = 5}) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return cardSkeleton(height: 80);
      },
    );
  }

  /// Shimmer skeleton
  static Widget shimmerCard({double height = 100, double? width}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + value * 2, 0),
              end: Alignment(1.0 + value * 2, 0),
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
            ),
          ),
        );
      },
    );
  }
}

/// Empty state widgets
class AppEmptyState {
  /// Generic empty state
  static Widget empty({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    );
  }

  /// No reviews empty state
  static Widget noReviews() {
    return empty(
      icon: Icons.rate_review_outlined,
      title: 'لا توجد تقييمات بعد',
      subtitle: 'عندما يقوم العملاء بإرسال تقييمات، ستظهر هنا',
    );
  }

  /// No results found
  static Widget noResults() {
    return empty(
      icon: Icons.search_off,
      title: 'لا توجد نتائج',
      subtitle: 'جرب البحث باستخدام كلمات مختلفة',
    );
  }

  /// Network error
  static Widget networkError({VoidCallback? onRetry}) {
    return empty(
      icon: Icons.cloud_off,
      title: 'فشل الاتصال بالخادم',
      subtitle: 'يرجى التحقق من الاتصال بالإنترنت',
      action: onRetry != null
          ? ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            )
          : null,
    );
  }
}
