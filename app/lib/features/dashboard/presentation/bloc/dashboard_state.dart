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
  final List<dynamic> latestReviews;

  const DashboardLoaded(this.dashboardData, {this.latestReviews = const []});

  @override
  List<Object?> get props => [dashboardData, latestReviews];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
