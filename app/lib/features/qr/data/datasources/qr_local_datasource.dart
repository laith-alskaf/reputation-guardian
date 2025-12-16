import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class QRLocalDataSource {
  Future<String?> getCachedQR();
  Future<void> cacheQR(String qrCode);
}

@Injectable(as: QRLocalDataSource)
class QRLocalDataSourceImpl implements QRLocalDataSource {
  final SharedPreferences sharedPreferences;

  QRLocalDataSourceImpl(this.sharedPreferences);

  static const String _qrCodeKey = 'cached_qr_code';

  @override
  Future<String?> getCachedQR() async {
    return sharedPreferences.getString(_qrCodeKey);
  }

  @override
  Future<void> cacheQR(String qrCode) async {
    await sharedPreferences.setString(_qrCodeKey, qrCode);
  }
}
