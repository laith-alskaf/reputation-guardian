import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<bool> hasToken();
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSourceImpl(this.secureStorage);

  @override
  Future<void> saveToken(String token) async {
    try {
      await secureStorage.write(key: AppConstants.authTokenKey, value: token);
    } catch (e) {
      throw CacheException('فشل في حفظ التوكن');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await secureStorage.read(key: AppConstants.authTokenKey);
    } catch (e) {
      throw CacheException('فشل في قراءة التوكن');
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await secureStorage.delete(key: AppConstants.authTokenKey);
    } catch (e) {
      throw CacheException('فشل في حذف التوكن');
    }
  }

  @override
  Future<bool> hasToken() async {
    try {
      final token = await secureStorage.read(key: AppConstants.authTokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
