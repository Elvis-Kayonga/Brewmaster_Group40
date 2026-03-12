// test/properties/pagination_properties_test.dart
//
// Property-based tests for task 31.2: PaginatedResult model and
// pagination invariants using pure in-memory fakes (no Firebase needed).
//
// Developer: Developer 6

import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';

// ---------------------------------------------------------------------------
// In-memory paginator — mirrors the Firestore cursor pattern
// ---------------------------------------------------------------------------

/// Simulates cursor-based pagination over an in-memory list.
class FakePaginator<T> {
  final List<T> _allItems;

  FakePaginator(this._allItems);

  PaginatedResult<T> getPage({int pageSize = 5, int? cursorIndex}) {
    final start = cursorIndex == null ? 0 : cursorIndex + 1;
    final end = start + pageSize + 1; // fetch one extra to detect hasMore
    final slice = _allItems.sublist(
        start, end > _allItems.length ? _allItems.length : end);

    final hasMore = slice.length > pageSize;
    final items = hasMore ? slice.sublist(0, pageSize) : slice;

    // Cursor = index of last item returned (opaque int as stand-in for DocumentSnapshot)
    final cursor = items.isNotEmpty ? start + items.length - 1 : null;

    return PaginatedResult<T>(items: items, hasMore: hasMore, cursor: cursor);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PaginatedResult model (task 31.2)', () {
    test('isEmpty is true for empty items', () {
      const page = PaginatedResult<int>(items: [], hasMore: false);
      expect(page.isEmpty, isTrue);
    });

    test('isEmpty is false when items present', () {
      const page = PaginatedResult<int>(items: [1, 2], hasMore: false);
      expect(page.isEmpty, isFalse);
    });

    test('count equals items length', () {
      const page = PaginatedResult<int>(items: [1, 2, 3], hasMore: true);
      expect(page.count, 3);
    });

    test('cursor is null by default', () {
      const page = PaginatedResult<int>(items: [1], hasMore: false);
      expect(page.cursor, isNull);
    });

    test('cursor can carry an opaque value', () {
      const page = PaginatedResult<String>(
          items: ['a'], hasMore: true, cursor: 42);
      expect(page.cursor, 42);
    });

    test('withItem appends an item and preserves hasMore', () {
      const page =
          PaginatedResult<int>(items: [1, 2], hasMore: true, cursor: 1);
      final next = page.withItem(3);
      expect(next.items, [1, 2, 3]);
      expect(next.hasMore, isTrue);
      expect(next.cursor, 1);
    });
  });

  group('Pagination invariants — FakePaginator (task 31.2)', () {
    final source = List.generate(23, (i) => i); // 23 items, pageSize=5 → 5 pages

    test('first page returns pageSize items', () {
      final pager = FakePaginator(source);
      final page = pager.getPage(pageSize: 5);
      expect(page.count, 5);
    });

    test('first page hasMore is true when more pages exist', () {
      final pager = FakePaginator(source);
      expect(pager.getPage(pageSize: 5).hasMore, isTrue);
    });

    test('cursor advances correctly to next page', () {
      final pager = FakePaginator(source);
      final p1 = pager.getPage(pageSize: 5);
      final p2 = pager.getPage(pageSize: 5, cursorIndex: p1.cursor as int);
      expect(p2.items.first, 5); // starts after index 4
    });

    test('pages are non-overlapping', () {
      final pager = FakePaginator(source);
      final p1 = pager.getPage(pageSize: 5);
      final p2 = pager.getPage(pageSize: 5, cursorIndex: p1.cursor as int);
      final combined = {...p1.items, ...p2.items};
      expect(combined.length, p1.count + p2.count); // no duplicates
    });

    test('last page hasMore is false', () {
      final pager = FakePaginator(source);
      // 23 items / 10 per page → page 1 (0-9), page 2 (10-19), page 3 (20-22)
      final p1 = pager.getPage(pageSize: 10);
      final p2 =
          pager.getPage(pageSize: 10, cursorIndex: p1.cursor as int);
      final p3 =
          pager.getPage(pageSize: 10, cursorIndex: p2.cursor as int);
      expect(p3.hasMore, isFalse);
    });

    test('last page has the remaining items', () {
      final pager = FakePaginator(source);
      final p1 = pager.getPage(pageSize: 10);
      final p2 =
          pager.getPage(pageSize: 10, cursorIndex: p1.cursor as int);
      final p3 =
          pager.getPage(pageSize: 10, cursorIndex: p2.cursor as int);
      expect(p3.count, 3); // 23 - 10 - 10 = 3
    });

    test('all items are covered across pages', () {
      final pager = FakePaginator(source);
      final all = <int>[];
      int? cursor;
      do {
        final page = pager.getPage(pageSize: 7, cursorIndex: cursor);
        all.addAll(page.items);
        cursor = page.hasMore ? page.cursor as int : null;
      } while (cursor != null);
      expect(all, source);
    });

    test('empty source returns empty page with hasMore false', () {
      final pager = FakePaginator<int>([]);
      final page = pager.getPage();
      expect(page.isEmpty, isTrue);
      expect(page.hasMore, isFalse);
    });

    test('pageSize larger than total returns all items', () {
      final pager = FakePaginator(List.generate(3, (i) => i));
      final page = pager.getPage(pageSize: 100);
      expect(page.count, 3);
      expect(page.hasMore, isFalse);
    });

    test('pageSize of 1 paginates one item at a time', () {
      final pager = FakePaginator([10, 20, 30]);
      final p1 = pager.getPage(pageSize: 1);
      final p2 =
          pager.getPage(pageSize: 1, cursorIndex: p1.cursor as int);
      final p3 =
          pager.getPage(pageSize: 1, cursorIndex: p2.cursor as int);
      expect(p1.items, [10]);
      expect(p2.items, [20]);
      expect(p3.items, [30]);
      expect(p3.hasMore, isFalse);
    });
  });
}
