// test/bloc/saved_lots_bloc_test.dart
//
// Unit tests for SavedLotsBloc — add, remove, clear, duplicate guard.

import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/saved_lot.dart';
import 'package:brewmaster/presentation/blocs/saved_lots/saved_lots_bloc.dart';

import '../helpers/fake_repositories.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _now = DateTime(2026, 1, 1);

SavedLot _fakeLot({String id = 'listing-1'}) => SavedLot(
      listingId: id,
      farmerId: 'farmer-1',
      farmerName: 'Alice',
      variety: 'Arabica',
      pricePerKg: 5.0,
      availableQuantity: 100,
      location: 'Kenya',
      savedAt: _now,
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('SavedLotsBloc — initial state', () {
    test('starts with empty items', () {
      final bloc = SavedLotsBloc(userRepository: FakeUserRepository());
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.itemCount, 0);
      bloc.close();
    });
  });

  group('SavedLotsBloc — SavedLotAdded', () {
    test('adds a lot to empty list', () async {
      final bloc = SavedLotsBloc(userRepository: FakeUserRepository());
      final lot = _fakeLot();

      bloc.add(SavedLotAdded(lot));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.items, contains(lot));
      expect(bloc.state.itemCount, 1);
      expect(bloc.state.contains(lot.listingId), isTrue);

      bloc.close();
    });

    test('adds multiple different lots', () async {
      final bloc = SavedLotsBloc(userRepository: FakeUserRepository());
      final lot1 = _fakeLot(id: 'listing-1');
      final lot2 = _fakeLot(id: 'listing-2');

      bloc.add(SavedLotAdded(lot1));
      bloc.add(SavedLotAdded(lot2));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.itemCount, 2);
      expect(bloc.state.contains('listing-1'), isTrue);
      expect(bloc.state.contains('listing-2'), isTrue);

      bloc.close();
    });

    test('does not add duplicate (same listingId)', () async {
      final bloc = SavedLotsBloc(userRepository: FakeUserRepository());
      final lot = _fakeLot();

      bloc.add(SavedLotAdded(lot));
      bloc.add(SavedLotAdded(lot)); // duplicate
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.itemCount, 1);

      bloc.close();
    });
  });

  group('SavedLotsBloc — SavedLotRemoved', () {
    test('removes an existing lot', () async {
      final bloc = SavedLotsBloc(userRepository: FakeUserRepository());
      final lot = _fakeLot();

      bloc.add(SavedLotAdded(lot));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.itemCount, 1);

      bloc.add(const SavedLotRemoved('listing-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.items, isEmpty);
      expect(bloc.state.contains('listing-1'), isFalse);

      bloc.close();
    });

    test('removing a non-existent lot leaves state unchanged', () async {
      final bloc = SavedLotsBloc(userRepository: FakeUserRepository());
      final lot = _fakeLot(id: 'listing-1');

      bloc.add(SavedLotAdded(lot));
      await Future<void>.delayed(Duration.zero);

      bloc.add(const SavedLotRemoved('listing-999'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.itemCount, 1);

      bloc.close();
    });

    test('removes only the specified lot when multiple exist', () async {
      final bloc = SavedLotsBloc(userRepository: FakeUserRepository());
      bloc.add(SavedLotAdded(_fakeLot(id: 'listing-1')));
      bloc.add(SavedLotAdded(_fakeLot(id: 'listing-2')));
      await Future<void>.delayed(Duration.zero);

      bloc.add(const SavedLotRemoved('listing-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.itemCount, 1);
      expect(bloc.state.contains('listing-1'), isFalse);
      expect(bloc.state.contains('listing-2'), isTrue);

      bloc.close();
    });
  });

  group('SavedLotsBloc — SavedLotsCleared', () {
    test('clears all lots', () async {
      final bloc = SavedLotsBloc(userRepository: FakeUserRepository());
      bloc.add(SavedLotAdded(_fakeLot(id: 'listing-1')));
      bloc.add(SavedLotAdded(_fakeLot(id: 'listing-2')));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.itemCount, 2);

      bloc.add(const SavedLotsCleared());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.items, isEmpty);
      expect(bloc.state.itemCount, 0);

      bloc.close();
    });

    test('clearing empty state stays empty', () async {
      final bloc = SavedLotsBloc(userRepository: FakeUserRepository());

      bloc.add(const SavedLotsCleared());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.items, isEmpty);

      bloc.close();
    });
  });

  group('SavedLotsState — helpers', () {
    test('contains returns false for unknown id', () {
      final bloc = SavedLotsBloc(userRepository: FakeUserRepository());
      expect(bloc.state.contains('unknown'), isFalse);
      bloc.close();
    });

    test('itemCount reflects list length', () async {
      final bloc = SavedLotsBloc(userRepository: FakeUserRepository());
      expect(bloc.state.itemCount, 0);

      bloc.add(SavedLotAdded(_fakeLot()));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.itemCount, 1);

      bloc.close();
    });
  });

  group('SavedLotsState — equality', () {
    test('identical empty states are equal', () {
      expect(const SavedLotsState(), equals(const SavedLotsState()));
    });
  });
}
