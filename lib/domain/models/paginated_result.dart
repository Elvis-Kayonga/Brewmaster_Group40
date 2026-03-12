// lib/domain/models/paginated_result.dart
//
// Generic page result used by all paginated repository methods.
// The cursor is stored as Object? so the domain layer remains agnostic of
// Firestore's DocumentSnapshot type — the Firebase implementations store the
// actual DocumentSnapshot and callers pass it back opaquely for the next page.
//
// Requirements: 14.1, 14.2
// Developer: Developer 6

/// A single page of results of type [T].
class PaginatedResult<T> {
  /// Items in this page.
  final List<T> items;

  /// Whether at least one more page exists.
  final bool hasMore;

  /// Opaque cursor for fetching the next page.
  /// Pass this back as [startAfter] in the next call.
  /// Null when there is no next page or this is the first call.
  final Object? cursor;

  const PaginatedResult({
    required this.items,
    required this.hasMore,
    this.cursor,
  });

  /// Convenience: true when no items were returned.
  bool get isEmpty => items.isEmpty;

  /// Number of items in this page.
  int get count => items.length;

  /// Returns a new page with an additional item appended. Useful in tests.
  PaginatedResult<T> withItem(T item) => PaginatedResult<T>(
        items: [...items, item],
        hasMore: hasMore,
        cursor: cursor,
      );
}
