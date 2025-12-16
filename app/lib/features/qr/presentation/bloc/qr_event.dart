import 'package:equatable/equatable.dart';

abstract class QREvent extends Equatable {
  const QREvent();

  @override
  List<Object> get props => [];
}

class LoadQRCode extends QREvent {
  const LoadQRCode();
}

class GenerateQR extends QREvent {
  const GenerateQR();
}

class LoadCachedQR extends QREvent {
  const LoadCachedQR();
}

class DownloadQR extends QREvent {
  final String qrCode;

  const DownloadQR(this.qrCode);

  @override
  List<Object> get props => [qrCode];
}

class ShareQR extends QREvent {
  final String qrCode;

  const ShareQR(this.qrCode);

  @override
  List<Object> get props => [qrCode];
}
