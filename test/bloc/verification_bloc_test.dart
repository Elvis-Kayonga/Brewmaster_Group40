// test/bloc/verification_bloc_test.dart
//
// Unit tests for VerificationBloc — load status, submit, real-time stream.
// Requirements: 7.1, 7.2, 7.3

import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/verification_request.dart';
import 'package:brewmaster/domain/repositories/verification_repository.dart';
import 'package:brewmaster/presentation/blocs/verification/verification_bloc.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _now = DateTime(2026, 1, 1);

VerificationRequest _fakeRequest({
  VerificationStatus state = VerificationStatus.pending,
}) =>
    VerificationRequest(
      userId: 'user-1',
      state: state,
      documentUrls: ['https://example.com/doc.pdf'],
      updatedAt: _now,
    );

// ─── Fake repository ──────────────────────────────────────────────────────────

class _FakeVerificationRepository implements VerificationRepository {
  VerificationRequest? _request = _fakeRequest();
  Exception? _error;
  final StreamController<VerificationStatus> _statusController =
      StreamController<VerificationStatus>.broadcast();

  void setRequest(VerificationRequest? r) => _request = r;
  void setError(Exception e) => _error = e;
  void pushStatus(VerificationStatus s) => _statusController.add(s);

  @override
  Future<VerificationRequest?> getVerificationStatus(String userId) async {
    if (_error != null) throw _error!;
    return _request;
  }

  @override
  Stream<VerificationStatus> watchVerificationStatus(String userId) =>
      _statusController.stream;

  @override
  Future<void> submitVerificationRequest(
    String userId,
    List<File> documents,
  ) async {
    if (_error != null) throw _error!;
  }

  @override
  Future<String> uploadDocument(String userId, File document) async {
    if (_error != null) throw _error!;
    return 'https://example.com/doc.pdf';
  }

  @override
  Future<void> syncStatusToUserProfile(
    String userId,
    VerificationStatus status,
  ) async {}

  void dispose() => _statusController.close();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('VerificationBloc — initial state', () {
    test('starts in VerificationInitial', () {
      final repo = _FakeVerificationRepository();
      final bloc = VerificationBloc(repository: repo);
      expect(bloc.state, isA<VerificationInitial>());
      bloc.close();
      repo.dispose();
    });
  });

  group('VerificationBloc — VerificationStatusLoadRequested', () {
    test('emits VerificationLoading then VerificationStatusLoaded on success',
        () async {
      final repo = _FakeVerificationRepository();
      final bloc = VerificationBloc(repository: repo);
      final states = <VerificationState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const VerificationStatusLoadRequested('user-1'));
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s is VerificationLoading), isTrue);
      expect(states.last, isA<VerificationStatusLoaded>());

      final loaded = states.last as VerificationStatusLoaded;
      expect(loaded.status, VerificationStatus.pending);
      expect(loaded.request, isNotNull);

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });

    test('emits VerificationStatusLoaded with unverified when request is null',
        () async {
      final repo = _FakeVerificationRepository();
      repo.setRequest(null);
      final bloc = VerificationBloc(repository: repo);

      bloc.add(const VerificationStatusLoadRequested('user-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<VerificationStatusLoaded>());
      final loaded = bloc.state as VerificationStatusLoaded;
      expect(loaded.status, VerificationStatus.unverified);
      expect(loaded.request, isNull);
      expect(loaded.rejectionReason, isNull);

      bloc.close();
      repo.dispose();
    });

    test('emits VerificationFailure on exception', () async {
      final repo = _FakeVerificationRepository();
      repo.setError(Exception('network error'));
      final bloc = VerificationBloc(repository: repo);

      bloc.add(const VerificationStatusLoadRequested('user-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<VerificationFailure>());

      bloc.close();
      repo.dispose();
    });

    test('updates state when stream emits a new status', () async {
      final repo = _FakeVerificationRepository();
      final bloc = VerificationBloc(repository: repo);

      bloc.add(const VerificationStatusLoadRequested('user-1'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<VerificationStatusLoaded>());

      repo.pushStatus(VerificationStatus.verified);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<VerificationStatusLoaded>());
      expect(
        (bloc.state as VerificationStatusLoaded).status,
        VerificationStatus.verified,
      );

      bloc.close();
      repo.dispose();
    });
  });

  group('VerificationBloc — VerificationDocumentSubmitted', () {
    test('emits VerificationLoading then VerificationSubmitSuccess', () async {
      final repo = _FakeVerificationRepository();
      final bloc = VerificationBloc(repository: repo);
      final states = <VerificationState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(VerificationDocumentSubmitted(
        userId: 'user-1',
        documents: [],
      ));
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s is VerificationLoading), isTrue);
      expect(states.last, isA<VerificationSubmitSuccess>());

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });

    test('emits VerificationFailure when submit throws', () async {
      final repo = _FakeVerificationRepository();
      repo.setError(Exception('upload failed'));
      final bloc = VerificationBloc(repository: repo);

      bloc.add(VerificationDocumentSubmitted(
        userId: 'user-1',
        documents: [],
      ));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<VerificationFailure>());

      bloc.close();
      repo.dispose();
    });
  });

  group('VerificationState — equality', () {
    test('VerificationInitial instances are equal', () {
      expect(const VerificationInitial(), equals(const VerificationInitial()));
    });

    test('VerificationLoading instances are equal', () {
      expect(const VerificationLoading(), equals(const VerificationLoading()));
    });

    test('VerificationFailure equality based on message', () {
      expect(
        const VerificationFailure('err'),
        equals(const VerificationFailure('err')),
      );
    });

    test('VerificationSubmitSuccess instances are equal', () {
      expect(
        const VerificationSubmitSuccess(),
        equals(const VerificationSubmitSuccess()),
      );
    });
  });
}
