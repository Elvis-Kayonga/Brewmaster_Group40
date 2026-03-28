import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/saved_lot.dart';
import '../../../domain/repositories/user_repository.dart';

part 'saved_lots_event.dart';
part 'saved_lots_state.dart';

/// Wishlist BLoC. Persists saved listing IDs to Firestore via [UserRepository]
/// so they survive app restarts and contribute to farmer savedCount metrics.
class SavedLotsBloc extends Bloc<SavedLotsEvent, SavedLotsState> {
  final UserRepository _userRepository;
  final String? userId;

  SavedLotsBloc({required UserRepository userRepository, this.userId})
      : _userRepository = userRepository,
        super(const SavedLotsState()) {
    on<SavedLotAdded>(_onAdded);
    on<SavedLotRemoved>(_onRemoved);
    on<SavedLotsCleared>(_onCleared);
    on<SavedLotsLoaded>(_onLoaded);
  }

  Future<void> _onAdded(SavedLotAdded event, Emitter<SavedLotsState> emit) async {
    if (state.contains(event.lot.listingId)) return;
    emit(SavedLotsState(items: [...state.items, event.lot]));
    if (userId != null) {
      await _userRepository.saveListing(userId!, event.lot.listingId);
    }
  }

  Future<void> _onRemoved(SavedLotRemoved event, Emitter<SavedLotsState> emit) async {
    emit(SavedLotsState(
      items: state.items.where((l) => l.listingId != event.listingId).toList(),
    ));
    if (userId != null) {
      await _userRepository.unsaveListing(userId!, event.listingId);
    }
  }

  void _onCleared(SavedLotsCleared event, Emitter<SavedLotsState> emit) {
    emit(const SavedLotsState());
  }

  void _onLoaded(SavedLotsLoaded event, Emitter<SavedLotsState> emit) {
    emit(SavedLotsState(items: event.lots));
  }
}
