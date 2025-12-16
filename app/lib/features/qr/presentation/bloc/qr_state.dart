import 'package:equatable/equatable.dart';

abstract class QRState extends Equatable {
  const QRState();

  @override
  List<Object?> get props => [];
}

class QRInitial extends QRState {
  const QRInitial();
}

class QRLoading extends QRState {
  const QRLoading();
}

class QRLoaded extends QRState {
  final String qrCode;

  const QRLoaded(this.qrCode);

  @override
  List<Object?> get props => [qrCode];
}

class QRError extends QRState {
  final String message;

  const QRError(this.message);

  @override
  List<Object?> get props => [message];
}
