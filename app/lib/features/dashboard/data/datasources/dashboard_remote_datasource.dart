import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardModel> getDashboard();
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
        // The API returns nested structure: { data: { data: {...}, message, success } }
        final outerData = response.data;
        if (outerData is Map<String, dynamic>) {
          // Check if there's a nested 'data' field
          if (outerData.containsKey('data')) {
            final innerData = outerData['data'];
            if (innerData is Map<String, dynamic>) {
              // Use the inner data to create the model
              print('✅ Dashboard Data Loaded Successfully');
              return DashboardModel.fromJson(innerData);
            }
          }
          // If no nested structure, use the outer data directly
          return DashboardModel.fromJson(outerData);
        }
        throw ServerException(message: 'Invalid response format from server');
      } else {
        throw ServerException(
          message: 'Failed to load dashboard: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException(
          message: 'Session expired, please login again',
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(message: 'Connection timeout, please try again');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(message: 'No internet connection');
      } else {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Server error occurred',
        );
      }
    } catch (e) {
      throw ServerException(message: 'Unexpected error occurred: $e');
    }
  }
}
