class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api-reputation-guardian.vercel.app';
  static const String devBaseUrl = 'http://127.0.0.1:5000';
  
  // API Endpoints
  static const String registerEndpoint = '/register';
  static const String loginEndpoint = '/login';
  static const String logoutEndpoint = '/logout';
  static const String dashboardEndpoint = '/dashboard';
  static const String profileEndpoint = '/profile';
  static const String generateQrEndpoint = '/generate-qr';
  static const String getQrEndpoint = '/qr';
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String shopInfoKey = 'shop_info';
  static const String userPreferencesKey = 'user_preferences';
  static const String themeKey = 'theme_mode';
  
  // App Configuration
  static const String appName = 'حارس السمعة';
  static const String appVersion = '1.0.0';
  static const Duration requestTimeout = Duration(seconds: 60);
  static const int retryAttempts = 3;
  
  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;
  
  // Validation
  static const int passwordMinLength = 6;
  static const int shopNameMinLength = 2;
}
