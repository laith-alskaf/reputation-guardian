import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_model.dart';

abstract class DashboardLocalDataSource {
  Future<DashboardModel?> getCachedDashboard();
  Future<void> cacheDashboard(DashboardModel dashboard);
  Future<void> clearCache();
}

@LazySingleton(as: DashboardLocalDataSource)
class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  static const String _dashboardCacheKey = 'dashboard_cache';
  static const String _cacheTimeKey = 'dashboard_cache_time';
  static const Duration _cacheValidity = Duration(minutes: 5);

  final SharedPreferences sharedPreferences;

  DashboardLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<DashboardModel?> getCachedDashboard() async {
    try {
      final cacheTimeString = sharedPreferences.getString(_cacheTimeKey);
      final cachedData = sharedPreferences.getString(_dashboardCacheKey);

      if (cacheTimeString == null || cachedData == null) {
        return null;
      }

      final cacheTime = DateTime.parse(cacheTimeString);
      final now = DateTime.now();

      // Check if cache is still valid
      if (now.difference(cacheTime) > _cacheValidity) {
        await clearCache();
        return null;
      }

      // Parse and return cached data
      // Note: For simplicity, we're not caching for now
      // You can implement JSON parsing here if needed
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheDashboard(DashboardModel dashboard) async {
    try {
      // Save cache time
      await sharedPreferences.setString(
        _cacheTimeKey,
        DateTime.now().toIso8601String(),
      );

      // Note: For simplicity, we're not caching the full object
      // You can implement JSON encoding here if needed
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove(_dashboardCacheKey);
      await sharedPreferences.remove(_cacheTimeKey);
    } catch (e) {
      // Silently fail
    }
  }
}
