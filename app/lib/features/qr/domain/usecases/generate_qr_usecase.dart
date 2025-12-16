import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../repositories/qr_repository.dart';

@injectable
class GenerateQRUseCase {
  final QRRepository repository;

  GenerateQRUseCase(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.generateQR();
  }
}
