import 'package:flutter/material.dart';

/// Responsive extensions for BuildContext
extension ResponsiveExtensions on BuildContext {
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if device is mobile (width < 600)
  bool get isMobile => screenWidth < 600;

  /// Check if device is tablet (600 <= width < 900)
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;

  /// Check if device is desktop (width >= 900)
  bool get isDesktop => screenWidth >= 900;

  /// Get responsive value based on screen size
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Get responsive padding
  EdgeInsets get responsivePadding => EdgeInsets.all(
        isMobile ? 16.0 : (isTablet ? 24.0 : 32.0),
      );

  /// Get responsive horizontal padding
  EdgeInsets get responsiveHorizontalPadding => EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : (isTablet ? 24.0 : 32.0),
      );
}

/// Responsive spacing utility
class ResponsiveSpacing {
  static double small(BuildContext context) {
    return context.isMobile ? 8.0 : 12.0;
  }

  static double medium(BuildContext context) {
    return context.isMobile ? 16.0 : 24.0;
  }

  static double large(BuildContext context) {
    return context.isMobile ? 24.0 : 32.0;
  }

  static double xlarge(BuildContext context) {
    return context.isMobile ? 32.0 : 48.0;
  }
}

/// Responsive font sizes
class ResponsiveFontSizes {
  static double small(BuildContext context) {
    return context.isMobile ? 12.0 : 14.0;
  }

  static double body(BuildContext context) {
    return context.isMobile ? 14.0 : 16.0;
  }

  static double title(BuildContext context) {
    return context.isMobile ? 18.0 : 20.0;
  }

  static double heading(BuildContext context) {
    return context.isMobile ? 24.0 : 28.0;
  }

  static double display(BuildContext context) {
    return context.isMobile ? 28.0 : 32.0;
  }
}
