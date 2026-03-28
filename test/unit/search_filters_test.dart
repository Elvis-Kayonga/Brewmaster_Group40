import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/search_filters.dart';

void main() {
  group('SearchFilters', () {
    test('default constructor creates empty filters', () {
      const filters = SearchFilters();
      expect(filters.query, isNull);
      expect(filters.method, isNull);
      expect(filters.country, isNull);
      expect(filters.minPrice, isNull);
      expect(filters.maxPrice, isNull);
      expect(filters.minAltitude, isNull);
      expect(filters.maxAltitude, isNull);
    });

    test('hasActiveFilters is false when all fields are null', () {
      const filters = SearchFilters();
      expect(filters.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters is true when query is set', () {
      const filters = SearchFilters(query: 'arabica');
      expect(filters.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters is true when method is set', () {
      const filters = SearchFilters(method: 'washed');
      expect(filters.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters is true when country is set', () {
      const filters = SearchFilters(country: 'Rwanda');
      expect(filters.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters is true when minPrice is set', () {
      const filters = SearchFilters(minPrice: 5.0);
      expect(filters.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters is true when maxPrice is set', () {
      const filters = SearchFilters(maxPrice: 20.0);
      expect(filters.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters is true when minAltitude is set', () {
      const filters = SearchFilters(minAltitude: 1500.0);
      expect(filters.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters is true when maxAltitude is set', () {
      const filters = SearchFilters(maxAltitude: 2500.0);
      expect(filters.hasActiveFilters, isTrue);
    });

    test('toJson returns empty map for default filters', () {
      const filters = SearchFilters();
      expect(filters.toJson(), isEmpty);
    });

    test('toJson serializes all fields correctly', () {
      const filters = SearchFilters(
        query: 'arabica',
        method: 'washed',
        country: 'Rwanda',
        minPrice: 5.0,
        maxPrice: 20.0,
        minAltitude: 1500.0,
        maxAltitude: 2500.0,
      );
      final json = filters.toJson();
      expect(json['query'], equals('arabica'));
      expect(json['method'], equals('washed'));
      expect(json['country'], equals('Rwanda'));
      expect(json['minPrice'], equals(5.0));
      expect(json['maxPrice'], equals(20.0));
      expect(json['minAltitude'], equals(1500.0));
      expect(json['maxAltitude'], equals(2500.0));
    });

    test('toJson omits null fields', () {
      const filters = SearchFilters(query: 'test');
      final json = filters.toJson();
      expect(json.containsKey('method'), isFalse);
      expect(json.containsKey('country'), isFalse);
    });

    test('fromJson creates correct instance', () {
      final json = {
        'query': 'arabica',
        'method': 'washed',
        'country': 'Rwanda',
        'minPrice': 5.0,
        'maxPrice': 20.0,
        'minAltitude': 1500.0,
        'maxAltitude': 2500.0,
      };
      final filters = SearchFilters.fromJson(json);
      expect(filters.query, equals('arabica'));
      expect(filters.method, equals('washed'));
      expect(filters.country, equals('Rwanda'));
      expect(filters.minPrice, equals(5.0));
      expect(filters.maxPrice, equals(20.0));
      expect(filters.minAltitude, equals(1500.0));
      expect(filters.maxAltitude, equals(2500.0));
    });

    test('fromJson handles integer prices (num conversion)', () {
      final json = {
        'minPrice': 5,
        'maxPrice': 20,
        'minAltitude': 1500,
        'maxAltitude': 2500,
      };
      final filters = SearchFilters.fromJson(json);
      expect(filters.minPrice, equals(5.0));
      expect(filters.maxPrice, equals(20.0));
      expect(filters.minAltitude, equals(1500.0));
      expect(filters.maxAltitude, equals(2500.0));
    });

    test('fromJson handles null values', () {
      final filters = SearchFilters.fromJson({});
      expect(filters.query, isNull);
      expect(filters.method, isNull);
    });

    test('copyWith overrides specific fields', () {
      const original = SearchFilters(query: 'arabica', country: 'Rwanda');
      final updated = original.copyWith(query: 'robusta');
      expect(updated.query, equals('robusta'));
      expect(updated.country, equals('Rwanda'));
    });

    test('copyWith keeps original values for unspecified fields', () {
      const original = SearchFilters(
        query: 'arabica',
        method: 'washed',
        minPrice: 5.0,
      );
      final updated = original.copyWith(maxPrice: 20.0);
      expect(updated.query, equals('arabica'));
      expect(updated.method, equals('washed'));
      expect(updated.minPrice, equals(5.0));
      expect(updated.maxPrice, equals(20.0));
    });

    test('clear returns empty SearchFilters', () {
      const filters = SearchFilters(query: 'arabica', country: 'Rwanda');
      final cleared = filters.clear();
      expect(cleared.hasActiveFilters, isFalse);
    });

    test('equality works for equal instances', () {
      const a = SearchFilters(query: 'arabica', country: 'Rwanda');
      const b = SearchFilters(query: 'arabica', country: 'Rwanda');
      expect(a, equals(b));
    });

    test('equality returns false for different instances', () {
      const a = SearchFilters(query: 'arabica');
      const b = SearchFilters(query: 'robusta');
      expect(a == b, isFalse);
    });

    test('hashCode is consistent for equal instances', () {
      const a = SearchFilters(query: 'arabica', country: 'Rwanda');
      const b = SearchFilters(query: 'arabica', country: 'Rwanda');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes all field values', () {
      const filters = SearchFilters(query: 'arabica', country: 'Rwanda');
      final str = filters.toString();
      expect(str, contains('arabica'));
      expect(str, contains('Rwanda'));
    });
  });
}
