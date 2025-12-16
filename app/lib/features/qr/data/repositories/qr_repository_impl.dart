import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/qr_repository.dart';
import '../datasources/qr_remote_datasource.dart';
import '../datasources/qr_local_datasource.dart';

@Injectable(as: QRRepository)
class QRRepositoryImpl implements QRRepository {
  final QRRemoteDataSource remoteDataSource;
  final QRLocalDataSource localDataSource;

  QRRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<Either<Failure, String>> generateQR() async {
    try {
      final qrCode = await remoteDataSource.generateQR();
      // Cache the QR code
      await localDataSource.cacheQR(qrCode);
      return Right(qrCode);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<String?> getCachedQR() async {
    try {
      return await localDataSource.getCachedQR();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheQR(String qrCode) async {
    await localDataSource.cacheQR(qrCode);
  }
}
