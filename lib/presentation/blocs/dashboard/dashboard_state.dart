part of 'dashboard_bloc.dart';

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

class FarmerDashboardLoaded extends DashboardState {
  final FarmerDashboard dashboard;

  const FarmerDashboardLoaded(this.dashboard);

  @override
  List<Object?> get props => [dashboard];
}

class BuyerDashboardLoaded extends DashboardState {
  final BuyerDashboard dashboard;

  const BuyerDashboardLoaded(this.dashboard);

  @override
  List<Object?> get props => [dashboard];
}

class DashboardFailure extends DashboardState {
  final String message;

  const DashboardFailure(this.message);

  @override
  List<Object?> get props => [message];
}
