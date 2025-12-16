import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/qr_repository.dart';

@lazySingleton
class GetLatestQRUseCase {
  final QRRepository repository;

  GetLatestQRUseCase(this.repository);

  Future<Either<Failure, String?>> call() async {
    return await repository.getLatestQR();
  }
}
