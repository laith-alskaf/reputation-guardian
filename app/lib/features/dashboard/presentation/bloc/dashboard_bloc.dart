import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/get_dashboard_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardUseCase getDashboardUseCase;

  DashboardBloc(this.getDashboardUseCase) : super(const DashboardInitial()) {
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

    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (dashboardData) => emit(DashboardLoaded(dashboardData)),
    );
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    // Keep current state while refreshing
    final currentState = state;

    final result = await getDashboardUseCase();

    result.fold(
      (failure) {
        // If refresh fails, keep current data and show error via snackbar
        // UI will handle this
        if (currentState is DashboardLoaded) {
          emit(currentState);
        } else {
          emit(DashboardError(failure.message));
        }
      },
      (dashboardData) => emit(DashboardLoaded(dashboardData)),
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

    // For now, we'll simulate QR generation
    // You can implement the actual API call using repository
    await Future.delayed(const Duration(seconds: 1));

    // Return to loaded state
    emit(DashboardLoaded(currentState.dashboardData));
  }
}
