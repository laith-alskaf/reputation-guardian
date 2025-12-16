import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(
    String email,
    String password,
    String shopName,
    String shopType,
  );
  Future<void> logout();
  Future<UserModel> getProfile();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await dio.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        // API returns: { "data": {...}, "message": "...", "status": "success" }
        final userData = response.data['data'];
        if (userData == null) {
          throw ServerException(message: 'البيانات غير صحيحة', statusCode: 500);
        }
        return UserModel.fromJson(userData as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'فشل تسجيل الدخول',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(message: 'انتهى وقت الاتصال');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException();
      } else if (e.response?.statusCode == 401) {
        throw UnauthorizedException(message: 'بيانات الدخول غير صحيحة');
      } else {
        throw ServerException(
          message: e.response?.data['message'] ?? 'حدث خطأ في الخادم',
          statusCode: e.response?.statusCode,
        );
      }
    }
  }

  @override
  Future<UserModel> register(
    String email,
    String password,
    String shopName,
    String shopType,
  ) async {
    try {
      final response = await dio.post(
        AppConstants.registerEndpoint,
        data: {
          'email': email,
          'password': password,
          'shop_name': shopName,
          'shop_type': shopType,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        return UserModel.fromJson(data);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'فشل إنشاء الحساب',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(message: 'انتهى وقت الاتصال');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException();
      } else if (e.response?.statusCode == 409) {
        throw ServerException(
          message: 'البريد الإلكتروني مستخدم مسبقاً',
          statusCode: 409,
        );
      } else {
        throw ServerException(
          message: e.response?.data['message'] ?? 'حدث خطأ في الخادم',
          statusCode: e.response?.statusCode,
        );
      }
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post(AppConstants.logoutEndpoint);
    } on DioException catch (e) {
      // Even if logout fails on server, we'll clear local data
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException();
      }
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await dio.get(AppConstants.profileEndpoint);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return UserModel.fromJson(data);
      } else {
        throw ServerException(
          message: 'فشل في تحميل الملف الشخصي',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(message: 'انتهى وقت الاتصال');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException();
      } else if (e.response?.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw ServerException(
          message: e.response?.data['message'] ?? 'حدث خطأ في الخادم',
          statusCode: e.response?.statusCode,
        );
      }
    }
  }
}
