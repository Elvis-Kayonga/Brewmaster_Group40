// test/bloc/connectivity_bloc_test.dart
//
// Unit tests for ConnectivityBloc — covers all states and event handlers.
// Requirements: 22.3

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/offline_sync_operation.dart';
import 'package:brewmaster/domain/repositories/offline_sync_repository.dart';
import 'package:brewmaster/presentation/blocs/connectivity/connectivity_bloc.dart';

// ─── Fake repository ─────────────────────────────────────────────────────────

class _FakeOfflineSyncRepository implements OfflineSyncRepository {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  /// Push a connectivity event from outside the test.
  void emit(bool isOnline) => _controller.add(isOnline);

  @override
  Stream<bool> watchConnectivity() => _controller.stream;

  @override
  Future<void> enqueueOperation(OfflineSyncOperation operation) async {}

  @override
  Future<int> processPendingQueue() async => 0;

  @override
  Future<void> clearQueue() async {}

  @override
  Future<List<OfflineSyncOperation>> getPendingOperations() async => [];

  void dispose() => _controller.close();
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ConnectivityBloc — initial state', () {
    test('starts in ConnectivityInitial', () {
      final repo = _FakeOfflineSyncRepository();
      final bloc = ConnectivityBloc(repository: repo);
      expect(bloc.state, isA<ConnectivityInitial>());
      bloc.close();
      repo.dispose();
    });
  });

  group('ConnectivityBloc — ConnectivityCheckRequested', () {
    test('emits ConnectivityUnknown', () async {
      final repo = _FakeOfflineSyncRepository();
      final bloc = ConnectivityBloc(repository: repo);

      bloc.add(const ConnectivityCheckRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ConnectivityUnknown>());
      bloc.close();
      repo.dispose();
    });
  });

  group('ConnectivityBloc — connectivity stream events', () {
    test('emits ConnectivityOnline when repository emits true', () async {
      final repo = _FakeOfflineSyncRepository();
      final bloc = ConnectivityBloc(repository: repo);

      repo.emit(true);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ConnectivityOnline>());
      bloc.close();
      repo.dispose();
    });

    test('emits ConnectivityOffline when repository emits false', () async {
      final repo = _FakeOfflineSyncRepository();
      final bloc = ConnectivityBloc(repository: repo);

      repo.emit(false);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ConnectivityOffline>());
      bloc.close();
      repo.dispose();
    });

    test('transitions online → offline → online correctly', () async {
      final repo = _FakeOfflineSyncRepository();
      final bloc = ConnectivityBloc(repository: repo);

      repo.emit(true);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<ConnectivityOnline>());

      repo.emit(false);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<ConnectivityOffline>());

      repo.emit(true);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<ConnectivityOnline>());

      bloc.close();
      repo.dispose();
    });
  });

  group('ConnectivityState — equality', () {
    test('ConnectivityInitial instances are equal', () {
      expect(const ConnectivityInitial(), equals(const ConnectivityInitial()));
    });

    test('ConnectivityOnline instances are equal', () {
      expect(const ConnectivityOnline(), equals(const ConnectivityOnline()));
    });

    test('ConnectivityOffline instances are equal', () {
      expect(const ConnectivityOffline(), equals(const ConnectivityOffline()));
    });

    test('ConnectivityUnknown instances are equal', () {
      expect(const ConnectivityUnknown(), equals(const ConnectivityUnknown()));
    });

    test('different state types are not equal', () {
      expect(
        const ConnectivityOnline(),
        isNot(equals(const ConnectivityOffline())),
      );
    });
  });
}
