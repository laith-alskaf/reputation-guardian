import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

// Server Failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ في الخادم']);
}

// Network Failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'لا يوجد اتصال بالإنترنت']);
}

// Cache Failures
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'خطأ في تحميل البيانات المحلية']);
}

// Authentication Failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([super.message = 'فشلت عملية المصادقة']);
}

// Validation Failures
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'بيانات غير صحيحة']);
}

// Unauthorized Failure
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'غير مصرح لك بهذا الإجراء']);
}

// Not Found Failure
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'البيانات المطلوبة غير موجودة']);
}
