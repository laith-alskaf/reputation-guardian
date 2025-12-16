import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_data.dart';
import '../repositories/dashboard_repository.dart';

@injectable
class GetDashboardUseCase {
  final DashboardRepository repository;

  GetDashboardUseCase(this.repository);

  Future<Either<Failure, DashboardData>> call() async {
    return await repository.getDashboard();
  }
}
