// test/bloc/profile_bloc_test.dart
//
// Unit tests for ProfileBloc — load, create, update, watch.
// Requirements: 1.1, 1.2, 1.3

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _now = DateTime(2026, 1, 1);

UserProfile _fakeProfile({String id = 'user-1'}) => UserProfile(
      id: id,
      email: 'farmer@test.com',
      phoneNumber: '+254700000000',
      role: UserRole.farmer,
      displayName: 'Alice Kamau',
      createdAt: _now,
      updatedAt: _now,
      country: 'Kenya',
    );

// ─── Fake repository ──────────────────────────────────────────────────────────

class _FakeUserRepository implements UserRepository {
  UserProfile? _profile = _fakeProfile();
  Exception? _error;
  final StreamController<UserProfile?> _watchController =
      StreamController<UserProfile?>.broadcast();

  void setProfile(UserProfile? p) => _profile = p;
  void setError(Exception e) => _error = e;
  void pushWatch(UserProfile? p) => _watchController.add(p);

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    if (_error != null) throw _error!;
    return _profile;
  }

  @override
  Future<UserProfile?> getUserProfileByEmail(String email) async {
    if (_error != null) throw _error!;
    return _profile;
  }

  @override
  Future<void> createUserProfile(UserProfile profile) async {
    if (_error != null) throw _error!;
  }

  @override
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    if (_error != null) throw _error!;
  }

  @override
  Stream<UserProfile?> watchUserProfile(String userId) =>
      _watchController.stream;

  void dispose() => _watchController.close();

  @override
  Future<void> saveListing(String userId, String listingId) async {}

  @override
  Future<void> unsaveListing(String userId, String listingId) async {}

  @override
  Future<List<String>> getSavedListings(String userId) async => [];
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ProfileBloc — initial state', () {
    test('starts in ProfileInitial', () {
      final repo = _FakeUserRepository();
      final bloc = ProfileBloc(userRepository: repo);
      expect(bloc.state, isA<ProfileInitial>());
      bloc.close();
      repo.dispose();
    });
  });

  group('ProfileBloc — ProfileLoadRequested', () {
    test('emits ProfileLoading then ProfileLoaded when profile found',
        () async {
      final repo = _FakeUserRepository();
      final bloc = ProfileBloc(userRepository: repo);
      final states = <ProfileState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const ProfileLoadRequested('user-1'));
      await Future<void>.delayed(Duration.zero);

      expect(states.first, isA<ProfileLoading>());
      expect(states.last, isA<ProfileLoaded>());
      expect((states.last as ProfileLoaded).profile.displayName, 'Alice Kamau');

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });

    test('emits ProfileFailure when profile not found (null)', () async {
      final repo = _FakeUserRepository();
      repo.setProfile(null);
      final bloc = ProfileBloc(userRepository: repo);

      bloc.add(const ProfileLoadRequested('missing'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ProfileFailure>());
      expect((bloc.state as ProfileFailure).message, 'Profile not found.');

      bloc.close();
      repo.dispose();
    });

    test('emits ProfileFailure on exception', () async {
      final repo = _FakeUserRepository();
      repo.setError(Exception('firebase error'));
      final bloc = ProfileBloc(userRepository: repo);

      bloc.add(const ProfileLoadRequested('user-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ProfileFailure>());

      bloc.close();
      repo.dispose();
    });
  });

  group('ProfileBloc — ProfileCreateRequested', () {
    test('emits ProfileLoading then ProfileCreateSuccess', () async {
      final repo = _FakeUserRepository();
      final bloc = ProfileBloc(userRepository: repo);
      final profile = _fakeProfile();
      final states = <ProfileState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(ProfileCreateRequested(profile));
      await Future<void>.delayed(Duration.zero);

      expect(states.first, isA<ProfileLoading>());
      expect(states.last, isA<ProfileCreateSuccess>());
      expect((states.last as ProfileCreateSuccess).profile.id, 'user-1');

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });

    test('emits ProfileFailure on exception', () async {
      final repo = _FakeUserRepository();
      repo.setError(Exception('create failed'));
      final bloc = ProfileBloc(userRepository: repo);

      bloc.add(ProfileCreateRequested(_fakeProfile()));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ProfileFailure>());

      bloc.close();
      repo.dispose();
    });
  });

  group('ProfileBloc — ProfileUpdateRequested', () {
    test('emits ProfileUpdateSuccess with updated profile', () async {
      final repo = _FakeUserRepository();
      final bloc = ProfileBloc(userRepository: repo);

      bloc.add(const ProfileUpdateRequested(
        userId: 'user-1',
        updates: {'displayName': 'Alice Updated'},
      ));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ProfileUpdateSuccess>());

      bloc.close();
      repo.dispose();
    });

    test('emits ProfileFailure when profile not found after update', () async {
      final bloc = ProfileBloc(userRepository: _UpdateThenNullRepo());

      bloc.add(const ProfileUpdateRequested(
        userId: 'user-1',
        updates: {'displayName': 'New Name'},
      ));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ProfileFailure>());
      expect((bloc.state as ProfileFailure).message,
          'Profile not found after update.');

      bloc.close();
    });

    test('emits ProfileFailure on exception', () async {
      final repo = _FakeUserRepository();
      repo.setError(Exception('update failed'));
      final bloc = ProfileBloc(userRepository: repo);

      bloc.add(const ProfileUpdateRequested(
        userId: 'user-1',
        updates: {'displayName': 'New'},
      ));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ProfileFailure>());

      bloc.close();
      repo.dispose();
    });
  });

  group('ProfileBloc — ProfileWatchRequested', () {
    test('emits ProfileLoaded when watch stream emits a profile', () async {
      final repo = _FakeUserRepository();
      final bloc = ProfileBloc(userRepository: repo);

      bloc.add(const ProfileWatchRequested('user-1'));
      await Future<void>.delayed(Duration.zero);

      repo.pushWatch(_fakeProfile());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ProfileLoaded>());

      bloc.close();
      repo.dispose();
    });

    test('emits ProfileFailure when watch stream emits null', () async {
      final repo = _FakeUserRepository();
      final bloc = ProfileBloc(userRepository: repo);

      bloc.add(const ProfileWatchRequested('user-1'));
      await Future<void>.delayed(Duration.zero);

      repo.pushWatch(null);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ProfileFailure>());

      bloc.close();
      repo.dispose();
    });
  });

  group('ProfileState — equality', () {
    test('ProfileInitial instances are equal', () {
      expect(const ProfileInitial(), equals(const ProfileInitial()));
    });

    test('ProfileLoading instances are equal', () {
      expect(const ProfileLoading(), equals(const ProfileLoading()));
    });

    test('ProfileFailure equality based on message', () {
      expect(
        const ProfileFailure('err'),
        equals(const ProfileFailure('err')),
      );
    });
  });
}

/// Stub: updateUserProfile succeeds, getUserProfile returns null.
class _UpdateThenNullRepo extends _FakeUserRepository {
  @override
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {}

  @override
  Future<UserProfile?> getUserProfile(String userId) async => null;
}
