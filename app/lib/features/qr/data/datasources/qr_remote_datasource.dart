import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

abstract class QRRemoteDataSource {
  Future<String> generateQR();
  Future<String?> getLatestQR();
}

@Injectable(as: QRRemoteDataSource)
class QRRemoteDataSourceImpl implements QRRemoteDataSource {
  final Dio dio;

  QRRemoteDataSourceImpl(this.dio);

  @override
  Future<String> generateQR() async {
    try {
      // Backend endpoint: POST /generate-qr
      final response = await dio.post('/generate-qr', data: {'size': 10});

      if (response.statusCode == 200 || response.statusCode == 201) {
        // API returns: { "data": { "qr_code": "..." }, "message": "...", "status": "success" }
        final responseData = response.data;

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final qrCode = responseData['data']['qr_code'];
          if (qrCode != null && qrCode.isNotEmpty) {
            print('✅ QR Generated successfully: ${qrCode.substring(0, 50)}...');
            return qrCode;
          }
        }

        throw Exception('Failed to generate QR code - Invalid data');
      } else {
        throw Exception('Failed to generate QR code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error generating QR: ${e.toString()}');
      throw Exception('Error generating QR: ${e.toString()}');
    }
  }

  @override
  Future<String?> getLatestQR() async {
    try {
      // Backend endpoint: GET /api/qr/{shop_id}
      // But we need shop_id, so this won't work without it
      // For now, return null and only use generate
      print('⚠️ getLatestQR: Not implemented (needs shop_id)');
      return null;
    } catch (e) {
      print('Error getting latest QR: ${e.toString()}');
      return null;
    }
  }
}
