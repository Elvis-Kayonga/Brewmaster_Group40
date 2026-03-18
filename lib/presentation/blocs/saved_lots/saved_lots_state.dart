part of 'saved_lots_bloc.dart';

class SavedLotsState extends Equatable {
  final List<SavedLot> items;

  const SavedLotsState({this.items = const []});

  int get itemCount => items.length;

  bool contains(String listingId) =>
      items.any((l) => l.listingId == listingId);

  @override
  List<Object?> get props => [items];
}
