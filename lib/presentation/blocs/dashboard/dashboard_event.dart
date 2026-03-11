part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class FarmerDashboardLoadRequested extends DashboardEvent {
  final String farmerId;

  const FarmerDashboardLoadRequested(this.farmerId);

  @override
  List<Object?> get props => [farmerId];
}

class BuyerDashboardLoadRequested extends DashboardEvent {
  final String buyerId;

  const BuyerDashboardLoadRequested(this.buyerId);

  @override
  List<Object?> get props => [buyerId];
}
