import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/get_dashboard_usecase.dart';
import '../../domain/usecases/generate_qr_usecase.dart';
import '../../data/datasources/dashboard_local_datasource.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardUseCase getDashboardUseCase;
  final GenerateQRUseCase generateQRUseCase;
  final DashboardLocalDataSource localDataSource;

  DashboardBloc(
    this.getDashboardUseCase,
    this.generateQRUseCase,
    this.localDataSource,
  ) : super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
    on<GenerateQRCode>(_onGenerateQRCode);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());

    final result = await getDashboardUseCase();

    await result.fold(
      (failure) async => emit(DashboardError(failure.message)),
      (dashboardData) async {
        // If QR is null from API, try to load from local storage
        if (dashboardData.qrCode == null || dashboardData.qrCode!.isEmpty) {
          final cachedQR = await localDataSource.getQRCode();
          if (cachedQR != null && cachedQR.isNotEmpty) {
            // Create new dashboard data with cached QR
            final updatedData = dashboardData.copyWith(qrCode: cachedQR);
            emit(DashboardLoaded(updatedData));
            return;
          }
        }
        emit(DashboardLoaded(dashboardData));
      },
    );
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    // Keep current state while refreshing
    final currentState = state;

    final result = await getDashboardUseCase();

    await result.fold(
      (failure) async {
        // If refresh fails, keep current data
        if (currentState is DashboardLoaded) {
          emit(currentState);
        } else {
          emit(DashboardError(failure.message));
        }
      },
      (dashboardData) async {
        // If QR is null from API, try to load from local storage
        if (dashboardData.qrCode == null || dashboardData.qrCode!.isEmpty) {
          final cachedQR = await localDataSource.getQRCode();
          if (cachedQR != null && cachedQR.isNotEmpty) {
            final updatedData = dashboardData.copyWith(qrCode: cachedQR);
            emit(DashboardLoaded(updatedData));
            return;
          }
        }
        emit(DashboardLoaded(dashboardData));
      },
    );
  }

  Future<void> _onGenerateQRCode(
    GenerateQRCode event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;

    if (currentState is! DashboardLoaded) {
      return;
    }

    emit(const QRGenerating());

    // Call API to generate QR
    final result = await generateQRUseCase();

    await result.fold(
      (failure) async {
        // If QR generation fails, return to loaded state
        emit(DashboardLoaded(currentState.dashboardData));
      },
      (qrCode) async {
        // Save QR code locally
        await localDataSource.saveQRCode(qrCode);
        print('✅ QR saved, updating dashboard...');

        // Update current dashboard data with new QR immediately
        final updatedData = currentState.dashboardData.copyWith(qrCode: qrCode);
        emit(DashboardLoaded(updatedData));
      },
    );
  }
}
