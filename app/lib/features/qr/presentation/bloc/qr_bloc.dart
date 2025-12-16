import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import '../../domain/usecases/generate_qr_usecase.dart';
import '../../domain/usecases/get_latest_qr_usecase.dart';
import '../../domain/repositories/qr_repository.dart';
import 'qr_event.dart';
import 'qr_state.dart';

@injectable
class QRBloc extends Bloc<QREvent, QRState> {
  final GenerateQRUseCase generateQRUseCase;
  final GetLatestQRUseCase getLatestQRUseCase;
  final QRRepository qrRepository;

  QRBloc({
    required this.generateQRUseCase,
    required this.getLatestQRUseCase,
    required this.qrRepository,
  }) : super(const QRInitial()) {
    on<LoadQRCode>(_onLoadQRCode);
    on<GenerateQR>(_onGenerateQR);
    on<LoadCachedQR>(_onLoadCached);
    on<DownloadQR>(_onDownloadQR);
    on<ShareQR>(_onShareQR);
  }

  Future<void> _onLoadQRCode(LoadQRCode event, Emitter<QRState> emit) async {
    emit(const QRLoading());

    // Step 1: Try cache first
    final cachedQR = await qrRepository.getCachedQR();
    if (cachedQR != null && cachedQR.isNotEmpty) {
      print('📱 QR loaded from cache');
      emit(QRLoaded(cachedQR));
      return;
    }

    // Step 2: Try API (getLatestQR)
    print('📱 QR not in cache, fetching from API...');
    final result = await getLatestQRUseCase();

    result.fold(
      (failure) {
        print('📱 API fetch failed: ${failure.message}');
        // No QR found, stay in initial state so user can generate
        emit(const QRInitial());
      },
      (qrCode) {
        if (qrCode != null && qrCode.isNotEmpty) {
          print('📱 QR fetched from API successfully');
          emit(QRLoaded(qrCode));
        } else {
          print('📱 No QR found in API, user needs to generate');
          emit(const QRInitial());
        }
      },
    );
  }

  Future<void> _onGenerateQR(GenerateQR event, Emitter<QRState> emit) async {
    emit(const QRLoading());

    final result = await generateQRUseCase();

    result.fold((failure) => emit(QRError(failure.message)), (qrCode) {
      print('📱 QR generated and cached successfully');
      emit(QRLoaded(qrCode));
    });
  }

  Future<void> _onLoadCached(LoadCachedQR event, Emitter<QRState> emit) async {
    // Try to load cached QR code from local storage
    // For now, just emit initial state since cache is optional
    emit(const QRInitial());
  }

  Future<void> _onDownloadQR(DownloadQR event, Emitter<QRState> emit) async {
    try {
      // Decode base64 to bytes
      final base64String = event.qrCode.contains(',')
          ? event.qrCode.split(',').last
          : event.qrCode;
      final bytes = base64Decode(base64String);

      // Save to gallery using gal package
      await Gal.putImageBytes(
        Uint8List.fromList(bytes),
        name: 'QR_Code_${DateTime.now().millisecondsSinceEpoch}',
      );
      print('✅ QR code saved to gallery successfully');
    } catch (e) {
      print('❌ Error downloading QR: $e');
      emit(QRError('فشل تحميل رمز QR: ${e.toString()}'));
    }
  }

  Future<void> _onShareQR(ShareQR event, Emitter<QRState> emit) async {
    try {
      // Decode base64 to bytes
      final bytes = base64Decode(event.qrCode.split(',').last);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/qr_code_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      // Write QR image
      await file.writeAsBytes(bytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'QR Code - حارس السمعة',
        text: 'رمز QR لجمع تقييمات العملاء',
      );

      print('✅ QR code shared successfully');
    } catch (e) {
      print('❌ Error sharing QR: $e');
      emit(QRError('فشل مشاركة رمز QR: ${e.toString()}'));
    }
  }
}
