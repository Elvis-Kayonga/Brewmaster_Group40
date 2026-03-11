import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/buyer_dashboard.dart';
import '../../../domain/models/farmer_dashboard.dart';
import '../../../domain/repositories/dashboard_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

/// BLoC for farmer and buyer dashboard data.
///
/// Events: [DashboardLoadRequested]
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5
/// Developer: Developer 5
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;

  DashboardBloc({required DashboardRepository repository})
      : _repository = repository,
        super(const DashboardInitial()) {
    on<FarmerDashboardLoadRequested>(_onLoadFarmer);
    on<BuyerDashboardLoadRequested>(_onLoadBuyer);
  }

  Future<void> _onLoadFarmer(
    FarmerDashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    try {
      final dashboard = await _repository.getFarmerDashboard(event.farmerId);
      emit(FarmerDashboardLoaded(dashboard));
    } catch (e) {
      emit(DashboardFailure(e.toString()));
    }
  }

  Future<void> _onLoadBuyer(
    BuyerDashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    try {
      final dashboard = await _repository.getBuyerDashboard(event.buyerId);
      emit(BuyerDashboardLoaded(dashboard));
    } catch (e) {
      emit(DashboardFailure(e.toString()));
    }
  }
}
