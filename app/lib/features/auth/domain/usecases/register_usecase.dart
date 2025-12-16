import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

@injectable
class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
    required String shopName,
    required String shopType,
  }) async {
    return await repository.register(
      email: email,
      password: password,
      shopName: shopName,
      shopType: shopType,
    );
  }
}
