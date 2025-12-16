import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class QRRepository {
  Future<Either<Failure, String>> generateQR();
  Future<String?> getCachedQR();
  Future<void> cacheQR(String qrCode);
}
