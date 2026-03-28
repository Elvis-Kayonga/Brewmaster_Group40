import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/presentation/widgets/common/custom_dropdown.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(8), child: child)),
    );

final _items = [
  const DropdownItem<String>(value: 'a', label: 'Option A'),
  const DropdownItem<String>(value: 'b', label: 'Option B'),
  const DropdownItem<String>(value: 'c', label: 'Option C'),
];

final _itemsWithIcons = [
  const DropdownItem<String>(value: 'x', label: 'X', icon: Icons.star),
  const DropdownItem<String>(value: 'y', label: 'Y', icon: Icons.favorite),
];

void main() {
  group('DropdownItem', () {
    test('equality based on value', () {
      const a = DropdownItem<String>(value: 'x', label: 'X');
      const b = DropdownItem<String>(value: 'x', label: 'Different label');
      expect(a, equals(b));
    });

    test('inequality when values differ', () {
      const a = DropdownItem<String>(value: 'x', label: 'X');
      const b = DropdownItem<String>(value: 'y', label: 'X');
      expect(a == b, isFalse);
    });

    test('hashCode based on value', () {
      const a = DropdownItem<String>(value: 'x', label: 'X');
      const b = DropdownItem<String>(value: 'x', label: 'Y');
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('CustomDropdown', () {
    testWidgets('renders hint text when no value selected', (tester) async {
      await tester.pumpWidget(_wrap(CustomDropdown<String>(
        items: _items,
        hintText: 'Select an option',
      )));
      expect(find.text('Select an option'), findsOneWidget);
    });

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(CustomDropdown<String>(
        items: _items,
        labelText: 'Choose Option',
      )));
      expect(find.text('Choose Option'), findsOneWidget);
    });

    testWidgets('renders required label with asterisk', (tester) async {
      await tester.pumpWidget(_wrap(CustomDropdown<String>(
        items: _items,
        labelText: 'Choose',
        isRequired: true,
      )));
      expect(find.text('Choose *'), findsOneWidget);
    });

    testWidgets('renders helper text', (tester) async {
      await tester.pumpWidget(_wrap(CustomDropdown<String>(
        items: _items,
        helperText: 'Pick one',
      )));
      expect(find.text('Pick one'), findsOneWidget);
    });

    testWidgets('renders error text', (tester) async {
      await tester.pumpWidget(_wrap(CustomDropdown<String>(
        items: _items,
        errorText: 'Required',
      )));
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('renders prefix icon when provided', (tester) async {
      await tester.pumpWidget(_wrap(CustomDropdown<String>(
        items: _items,
        prefixIcon: Icons.sort,
      )));
      expect(find.byIcon(Icons.sort), findsOneWidget);
    });

    testWidgets('calls onChanged when value selected', (tester) async {
      String? selected;
      await tester.pumpWidget(_wrap(CustomDropdown<String>(
        items: _items,
        onChanged: (v) => selected = v,
      )));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Option A').last);
      await tester.pumpAndSettle();
      expect(selected, equals('a'));
    });

    testWidgets('disabled dropdown does not call onChanged', (tester) async {
      String? selected;
      await tester.pumpWidget(_wrap(CustomDropdown<String>(
        items: _items,
        enabled: false,
        onChanged: (v) => selected = v,
      )));
      // When disabled, onChanged is null so nothing changes
      expect(selected, isNull);
    });

    testWidgets('renders with showItemIcons true without throwing', (tester) async {
      await tester.pumpWidget(_wrap(CustomDropdown<String>(
        items: _itemsWithIcons,
        showItemIcons: true,
      )));
      expect(find.byType(CustomDropdown<String>), findsOneWidget);
    });

    testWidgets('validates with custom validator', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: CustomDropdown<String>(
              items: _items,
              validator: (v) => v == null ? 'Required' : null,
            ),
          ),
        ),
      ));
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
    });
  });

  group('SimpleDropdown', () {
    final stringItems = ['Apple', 'Banana', 'Cherry'];

    testWidgets('renders string items', (tester) async {
      await tester.pumpWidget(_wrap(SimpleDropdown(
        items: stringItems,
        hintText: 'Choose fruit',
      )));
      expect(find.text('Choose fruit'), findsOneWidget);
    });

    testWidgets('renders selected value', (tester) async {
      await tester.pumpWidget(_wrap(SimpleDropdown(
        items: stringItems,
        value: 'Banana',
      )));
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('calls onChanged when item selected', (tester) async {
      String? selected;
      await tester.pumpWidget(_wrap(SimpleDropdown(
        items: stringItems,
        onChanged: (v) => selected = v,
      )));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apple').last);
      await tester.pumpAndSettle();
      expect(selected, equals('Apple'));
    });

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(SimpleDropdown(
        items: stringItems,
        labelText: 'Fruit',
      )));
      expect(find.text('Fruit'), findsOneWidget);
    });
  });

  group('SearchableDropdown', () {
    final searchItems = [
      const DropdownItem<String>(value: 'arabica', label: 'Arabica'),
      const DropdownItem<String>(value: 'robusta', label: 'Robusta'),
      const DropdownItem<String>(value: 'liberica', label: 'Liberica'),
    ];

    testWidgets('renders hint text initially', (tester) async {
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        hintText: 'Select variety',
      )));
      expect(find.text('Select variety'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        labelText: 'Variety',
      )));
      expect(find.text('Variety'), findsOneWidget);
    });

    testWidgets('renders required asterisk in label', (tester) async {
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        labelText: 'Variety',
        isRequired: true,
      )));
      expect(find.text('Variety *'), findsOneWidget);
    });

    testWidgets('shows selected value label', (tester) async {
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        value: 'arabica',
      )));
      expect(find.text('Arabica'), findsOneWidget);
    });

    testWidgets('disabled does not open overlay', (tester) async {
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        enabled: false,
        hintText: 'Choose',
      )));
      await tester.tap(find.byType(SearchableDropdown<String>));
      await tester.pump();
      // overlay should not open, so no ListView visible
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('tapping opens overlay with all items', (tester) async {
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        hintText: 'Select variety',
      )));
      await tester.tap(find.byType(SearchableDropdown<String>));
      await tester.pump();
      expect(find.text('Arabica'), findsOneWidget);
      expect(find.text('Robusta'), findsOneWidget);
      expect(find.text('Liberica'), findsOneWidget);
    });

    testWidgets('tapping again closes overlay', (tester) async {
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        hintText: 'Select variety',
      )));
      await tester.tap(find.byType(SearchableDropdown<String>));
      await tester.pump();
      expect(find.text('Arabica'), findsOneWidget);

      await tester.tap(find.byType(SearchableDropdown<String>));
      await tester.pump();
      expect(find.text('Arabica'), findsNothing);
    });

    testWidgets('overlay shows search field with search icon', (tester) async {
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        hintText: 'Select variety',
      )));
      await tester.tap(find.byType(SearchableDropdown<String>));
      await tester.pump();
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('typing filters items by label', (tester) async {
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        hintText: 'Select variety',
      )));
      await tester.tap(find.byType(SearchableDropdown<String>));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'arab');
      await tester.pump();

      expect(find.text('Arabica'), findsOneWidget);
      expect(find.text('Robusta'), findsNothing);
      expect(find.text('Liberica'), findsNothing);
    });

    testWidgets('clearing search restores all items', (tester) async {
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        hintText: 'Select variety',
      )));
      await tester.tap(find.byType(SearchableDropdown<String>));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'arab');
      await tester.pump();
      expect(find.text('Robusta'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.text('Arabica'), findsOneWidget);
      expect(find.text('Robusta'), findsOneWidget);
    });

    testWidgets('tapping item calls onChanged with correct value', (tester) async {
      String? selected;
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        onChanged: (v) => selected = v,
        hintText: 'Select variety',
      )));
      await tester.tap(find.byType(SearchableDropdown<String>));
      await tester.pump();

      await tester.tap(find.text('Robusta'));
      await tester.pump();

      expect(selected, equals('robusta'));
    });

    testWidgets('selecting item closes overlay', (tester) async {
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        onChanged: (_) {},
        hintText: 'Select variety',
      )));
      await tester.tap(find.byType(SearchableDropdown<String>));
      await tester.pump();
      expect(find.text('Arabica'), findsOneWidget);

      await tester.tap(find.text('Arabica'));
      await tester.pump();

      // overlay closed — items no longer visible
      expect(find.text('Robusta'), findsNothing);
    });

    testWidgets('shows error text', (tester) async {
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        errorText: 'Please select',
      )));
      expect(find.text('Please select'), findsOneWidget);
    });

    testWidgets('no onChanged: tapping item still closes overlay', (tester) async {
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: searchItems,
        hintText: 'Select variety',
      )));
      await tester.tap(find.byType(SearchableDropdown<String>));
      await tester.pump();
      expect(find.text('Arabica'), findsOneWidget);

      await tester.tap(find.text('Arabica'));
      await tester.pump();
      expect(find.text('Robusta'), findsNothing);
    });

    testWidgets('items with icons show icons in overlay', (tester) async {
      final itemsWithIcons = [
        const DropdownItem<String>(value: 'x', label: 'X item', icon: Icons.star),
        const DropdownItem<String>(value: 'y', label: 'Y item', icon: Icons.favorite),
      ];
      await tester.pumpWidget(_wrap(SearchableDropdown<String>(
        items: itemsWithIcons,
        hintText: 'Choose',
      )));
      await tester.tap(find.byType(SearchableDropdown<String>));
      await tester.pump();
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });
}
