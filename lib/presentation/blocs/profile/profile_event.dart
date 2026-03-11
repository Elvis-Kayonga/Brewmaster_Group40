part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load a user profile by uid.
class ProfileLoadRequested extends ProfileEvent {
  final String userId;
  const ProfileLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Create a new Firestore profile document.
class ProfileCreateRequested extends ProfileEvent {
  final UserProfile profile;
  const ProfileCreateRequested(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Partially update an existing profile.
class ProfileUpdateRequested extends ProfileEvent {
  final String userId;
  final Map<String, dynamic> updates;
  const ProfileUpdateRequested({required this.userId, required this.updates});

  @override
  List<Object?> get props => [userId, updates];
}

/// Start watching a profile for real-time updates.
class ProfileWatchRequested extends ProfileEvent {
  final String userId;
  const ProfileWatchRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}
