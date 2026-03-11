import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository _userRepository;
  StreamSubscription<UserProfile?>? _profileSubscription;

  ProfileBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileCreateRequested>(_onCreate);
    on<ProfileUpdateRequested>(_onUpdate);
    on<ProfileWatchRequested>(_onWatch);
  }

  Future<void> _onLoad(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final profile = await _userRepository.getUserProfile(event.userId);
      if (profile != null) {
        emit(ProfileLoaded(profile));
      } else {
        emit(const ProfileFailure('Profile not found.'));
      }
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }

  Future<void> _onCreate(
    ProfileCreateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      await _userRepository.createUserProfile(event.profile);
      emit(ProfileCreateSuccess(event.profile));
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }

  Future<void> _onUpdate(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      await _userRepository.updateUserProfile(event.userId, event.updates);
      final updated = await _userRepository.getUserProfile(event.userId);
      if (updated != null) {
        emit(ProfileUpdateSuccess(updated));
      } else {
        emit(const ProfileFailure('Profile not found after update.'));
      }
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }

  Future<void> _onWatch(
    ProfileWatchRequested event,
    Emitter<ProfileState> emit,
  ) async {
    await _profileSubscription?.cancel();
    await emit.forEach<UserProfile?>(
      _userRepository.watchUserProfile(event.userId),
      onData: (profile) =>
          profile != null ? ProfileLoaded(profile) : const ProfileFailure('Profile not found.'),
      onError: (e, _) => ProfileFailure(e.toString()),
    );
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}
