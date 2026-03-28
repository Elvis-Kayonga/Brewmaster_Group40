// test/bloc/dashboard_bloc_test.dart
//
// Unit tests for DashboardBloc — farmer and buyer dashboard loading.
// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5

import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/buyer_dashboard.dart';
import 'package:brewmaster/domain/models/farmer_dashboard.dart';
import 'package:brewmaster/domain/repositories/dashboard_repository.dart';
import 'package:brewmaster/presentation/blocs/dashboard/dashboard_bloc.dart';

// ─── Fake repository ──────────────────────────────────────────────────────────

class _FakeDashboardRepository implements DashboardRepository {
  FarmerDashboard _farmerDash = const FarmerDashboard(
    activeListings: 3,
    totalEarnings: 1500.0,
    conversations: 5,
    savedCount: 120,
    responseRate: 0.9,
  );
  BuyerDashboard _buyerDash = const BuyerDashboard(
    totalPurchases: 2,
    conversations: 3,
    savedListings: 7,
  );
  Exception? _error;

  void setError(Exception e) => _error = e;
  void setFarmerDash(FarmerDashboard d) => _farmerDash = d;
  void setBuyerDash(BuyerDashboard d) => _buyerDash = d;

  @override
  Future<FarmerDashboard> getFarmerDashboard(String farmerId) async {
    if (_error != null) throw _error!;
    return _farmerDash;
  }

  @override
  Future<BuyerDashboard> getBuyerDashboard(String buyerId) async {
    if (_error != null) throw _error!;
    return _buyerDash;
  }

  @override
  Stream<FarmerDashboard> watchFarmerDashboard(String farmerId) =>
      const Stream.empty();

  @override
  Stream<BuyerDashboard> watchBuyerDashboard(String buyerId) =>
      const Stream.empty();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('DashboardBloc — initial state', () {
    test('starts in DashboardInitial', () {
      final bloc = DashboardBloc(repository: _FakeDashboardRepository());
      expect(bloc.state, isA<DashboardInitial>());
      bloc.close();
    });
  });

  group('DashboardBloc — FarmerDashboardLoadRequested', () {
    test('emits DashboardLoading then FarmerDashboardLoaded on success',
        () async {
      final repo = _FakeDashboardRepository();
      final bloc = DashboardBloc(repository: repo);
      final states = <DashboardState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const FarmerDashboardLoadRequested('farmer-1'));
      await Future<void>.delayed(Duration.zero);

      expect(states.first, isA<DashboardLoading>());
      expect(states.last, isA<FarmerDashboardLoaded>());

      final loaded = states.last as FarmerDashboardLoaded;
      expect(loaded.dashboard.activeListings, 3);
      expect(loaded.dashboard.totalEarnings, 1500.0);

      await sub.cancel();
      bloc.close();
    });

    test('emits DashboardFailure on exception', () async {
      final repo = _FakeDashboardRepository();
      repo.setError(Exception('firebase error'));
      final bloc = DashboardBloc(repository: repo);

      bloc.add(const FarmerDashboardLoadRequested('farmer-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<DashboardFailure>());

      bloc.close();
    });

    test('loads dashboard data with correct metrics', () async {
      final repo = _FakeDashboardRepository();
      repo.setFarmerDash(const FarmerDashboard(
        activeListings: 10,
        totalEarnings: 5000.0,
        conversations: 12,
        savedCount: 300,
        responseRate: 0.95,
        revenueChangePct: 12.5,
      ));
      final bloc = DashboardBloc(repository: repo);

      bloc.add(const FarmerDashboardLoadRequested('farmer-1'));
      await Future<void>.delayed(Duration.zero);

      final loaded = bloc.state as FarmerDashboardLoaded;
      expect(loaded.dashboard.activeListings, 10);
      expect(loaded.dashboard.revenueChangePct, 12.5);

      bloc.close();
    });
  });

  group('DashboardBloc — BuyerDashboardLoadRequested', () {
    test('emits DashboardLoading then BuyerDashboardLoaded on success',
        () async {
      final repo = _FakeDashboardRepository();
      final bloc = DashboardBloc(repository: repo);
      final states = <DashboardState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const BuyerDashboardLoadRequested('buyer-1'));
      await Future<void>.delayed(Duration.zero);

      expect(states.first, isA<DashboardLoading>());
      expect(states.last, isA<BuyerDashboardLoaded>());

      final loaded = states.last as BuyerDashboardLoaded;
      expect(loaded.dashboard.totalPurchases, 2);
      expect(loaded.dashboard.savedListings, 7);

      await sub.cancel();
      bloc.close();
    });

    test('emits DashboardFailure on exception', () async {
      final repo = _FakeDashboardRepository();
      repo.setError(Exception('network error'));
      final bloc = DashboardBloc(repository: repo);

      bloc.add(const BuyerDashboardLoadRequested('buyer-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<DashboardFailure>());
      expect((bloc.state as DashboardFailure).message,
          contains('network error'));

      bloc.close();
    });
  });

  group('DashboardState — equality', () {
    test('DashboardInitial instances are equal', () {
      expect(const DashboardInitial(), equals(const DashboardInitial()));
    });

    test('DashboardLoading instances are equal', () {
      expect(const DashboardLoading(), equals(const DashboardLoading()));
    });

    test('DashboardFailure equality based on message', () {
      expect(
        const DashboardFailure('err'),
        equals(const DashboardFailure('err')),
      );
    });
  });
}
