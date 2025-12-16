import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_data.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardData dashboardData;

  const DashboardLoaded(this.dashboardData);

  @override
  List<Object?> get props => [dashboardData];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

class QRGenerating extends DashboardState {
  const QRGenerating();
}

class QRGenerated extends DashboardState {
  final String qrCode;
  final DashboardData dashboardData;

  const QRGenerated(this.qrCode, this.dashboardData);

  @override
  List<Object?> get props => [qrCode, dashboardData];
}
