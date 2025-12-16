import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:reputation_guardian/features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../../../core/error/failures.dart';

@injectable
class GenerateQRUseCase {
  final DashboardRepository repository;

  GenerateQRUseCase(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.generateQR();
  }
}
