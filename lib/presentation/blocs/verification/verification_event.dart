// Feature: brewmaster-verification
// VerificationBloc events.
//
// Requirements: 7.1, 7.2
// Developer: Developer 1

part of 'verification_bloc.dart';

abstract class VerificationEvent extends Equatable {
  const VerificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load the current verification status for [userId].
class VerificationStatusLoadRequested extends VerificationEvent {
  final String userId;
  const VerificationStatusLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Submit documents for verification.
class VerificationDocumentSubmitted extends VerificationEvent {
  final String userId;
  final List<File> documents;

  const VerificationDocumentSubmitted({
    required this.userId,
    required this.documents,
  });

  @override
  List<Object?> get props => [userId, documents];
}

/// Internal: emitted when the status stream updates.
class _VerificationStatusChanged extends VerificationEvent {
  final VerificationStatus status;
  const _VerificationStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}
