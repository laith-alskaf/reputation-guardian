import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:reputation_guardian/features/qr/domain/usecases/generate_qr_usecase.dart';
import 'qr_event.dart';
import 'qr_state.dart';

@injectable
class QRBloc extends Bloc<QREvent, QRState> {
  final GenerateQRUseCase generateQRUseCase;

  QRBloc(this.generateQRUseCase) : super(const QRInitial()) {
    on<GenerateQR>(_onGenerateQR);
    on<LoadCachedQR>(_onLoadCached);
    on<DownloadQR>(_onDownloadQR);
    on<ShareQR>(_onShareQR);
  }

  Future<void> _onGenerateQR(GenerateQR event, Emitter<QRState> emit) async {
    emit(const QRLoading());

    final result = await generateQRUseCase();

    result.fold(
      (failure) => emit(QRError(failure.message)),
      (qrCode) => emit(QRLoaded(qrCode)),
    );
  }

  Future<void> _onLoadCached(LoadCachedQR event, Emitter<QRState> emit) async {
    // TODO: Implement cache loading
    emit(const QRInitial());
  }

  Future<void> _onDownloadQR(DownloadQR event, Emitter<QRState> emit) async {
    // TODO: Implement QR download
  }

  Future<void> _onShareQR(ShareQR event, Emitter<QRState> emit) async {
    // TODO: Implement QR sharing
  }
}
