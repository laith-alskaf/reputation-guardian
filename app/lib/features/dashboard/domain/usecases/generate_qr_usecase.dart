import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../repositories/dashboard_repository.dart';

@injectable
class GenerateQRUseCase {
  final DashboardRepository repository;

  GenerateQRUseCase(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.generateQR();
  }
}
