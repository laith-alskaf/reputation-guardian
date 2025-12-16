import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';

abstract class QRRemoteDataSource {
  Future<String> generateQR();
}

@Injectable(as: QRRemoteDataSource)
class QRRemoteDataSourceImpl implements QRRemoteDataSource {
  final Dio dio;

  QRRemoteDataSourceImpl(this.dio);

  @override
  Future<String> generateQR() async {
    try {
      final response = await dio.post(AppConstants.generateQrEndpoint);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return data['qr_code'] as String;
      }

      throw Exception('Failed to generate QR code');
    } catch (e) {
      throw Exception('Error generating QR: $e');
    }
  }
}
