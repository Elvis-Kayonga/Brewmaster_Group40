part of 'saved_lots_bloc.dart';

abstract class SavedLotsEvent extends Equatable {
  const SavedLotsEvent();
  @override
  List<Object?> get props => [];
}

class SavedLotAdded extends SavedLotsEvent {
  final SavedLot lot;
  const SavedLotAdded(this.lot);
  @override
  List<Object?> get props => [lot];
}

class SavedLotRemoved extends SavedLotsEvent {
  final String listingId;
  const SavedLotRemoved(this.listingId);
  @override
  List<Object?> get props => [listingId];
}

class SavedLotsCleared extends SavedLotsEvent {
  const SavedLotsCleared();
}

class SavedLotsLoaded extends SavedLotsEvent {
  final List<SavedLot> lots;
  const SavedLotsLoaded(this.lots);
  @override
  List<Object?> get props => [lots];
}
