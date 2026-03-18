// Feature: brewmaster-verification
// VerificationBloc states.
//
// Requirements: 7.1, 7.2
// Developer: Developer 1

part of 'verification_bloc.dart';

abstract class VerificationState extends Equatable {
  const VerificationState();

  @override
  List<Object?> get props => [];
}

class VerificationInitial extends VerificationState {
  const VerificationInitial();
}

class VerificationLoading extends VerificationState {
  const VerificationLoading();
}

class VerificationStatusLoaded extends VerificationState {
  final VerificationRequest? request;
  final VerificationStatus status;

  const VerificationStatusLoaded({required this.status, this.request});

  /// Convenience: rejection reason from the stored record, if any.
  String? get rejectionReason => request?.rejectionReason;

  @override
  List<Object?> get props => [status, request];
}

class VerificationSubmitSuccess extends VerificationState {
  const VerificationSubmitSuccess();
}

class VerificationFailure extends VerificationState {
  final String message;
  const VerificationFailure(this.message);

  @override
  List<Object?> get props => [message];
}
