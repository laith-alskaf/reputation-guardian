import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardModel> getDashboard();
  Future<String> generateQR();
}

@LazySingleton(as: DashboardRemoteDataSource)
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio dio;

  DashboardRemoteDataSourceImpl(this.dio);

  @override
  Future<DashboardModel> getDashboard() async {
    try {
      final response = await dio.get(AppConstants.dashboardEndpoint);

      if (response.statusCode == 200) {
        // API returns: { "data": {...}, "message": "...", "status": "success" }
        final data = response.data['data'];
        if (data == null) {
          throw ServerException(message: 'البيانات غير صحيحة');
        }
        return DashboardModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'فشل تحميل البيانات: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException(
          message: 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى',
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
          message: 'انتهى وقت الاتصال، يرجى المحاولة مرة أخرى',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(message: 'لا يوجد اتصال بالإنترنت');
      } else {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'حدث خطأ في الخادم',
        );
      }
    } catch (e) {
      throw ServerException(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<String> generateQR() async {
    try {
      final response = await dio.post(AppConstants.generateQrEndpoint);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final qrCode = response.data['qr_code'] as String?;
        if (qrCode != null) {
          return qrCode;
        } else {
          throw ServerException(message: 'فشل إنشاء رمز QR');
        }
      } else {
        throw ServerException(
          message: 'فشل إنشاء رمز QR: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException(
          message: 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى',
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
          message: 'انتهى وقت الاتصال، يرجى المحاولة مرة أخرى',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(message: 'لا يوجد اتصال بالإنترنت');
      } else {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'حدث خطأ في الخادم',
        );
      }
    } catch (e) {
      throw ServerException(message: 'حدث خطأ غير متوقع: $e');
    }
  }
}
