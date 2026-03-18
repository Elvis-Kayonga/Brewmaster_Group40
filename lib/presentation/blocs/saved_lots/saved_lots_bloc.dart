import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/saved_lot.dart';

part 'saved_lots_event.dart';
part 'saved_lots_state.dart';

/// In-memory wishlist BLoC. Persistence to Firestore
/// (users/{userId}/savedLots) can be layered in via a repository later.
class SavedLotsBloc extends Bloc<SavedLotsEvent, SavedLotsState> {
  SavedLotsBloc() : super(const SavedLotsState()) {
    on<SavedLotAdded>(_onAdded);
    on<SavedLotRemoved>(_onRemoved);
    on<SavedLotsCleared>(_onCleared);
  }

  void _onAdded(SavedLotAdded event, Emitter<SavedLotsState> emit) {
    if (state.contains(event.lot.listingId)) return; // already saved
    emit(SavedLotsState(items: [...state.items, event.lot]));
  }

  void _onRemoved(SavedLotRemoved event, Emitter<SavedLotsState> emit) {
    emit(SavedLotsState(
      items: state.items
          .where((l) => l.listingId != event.listingId)
          .toList(),
    ));
  }

  void _onCleared(SavedLotsCleared event, Emitter<SavedLotsState> emit) {
    emit(const SavedLotsState());
  }
}
