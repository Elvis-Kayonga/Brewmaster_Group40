// test/widgets/custom_button_test.dart
//
// Widget tests for CustomButton in custom_button.dart.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child));

void main() {
  // ---------------------------------------------------------------------------
  // ButtonType variants
  // ---------------------------------------------------------------------------
  group('ButtonType variants', () {
    for (final type in ButtonType.values) {
      testWidgets('type ${type.name} renders without throwing and shows label',
          (tester) async {
        await tester.pumpWidget(_wrap(CustomButton(
          text: 'Label ${type.name}',
          type: type,
          onPressed: () {},
        )));
        await tester.pump();
        expect(find.text('Label ${type.name}'), findsOneWidget);
      });
    }
  });

  // ---------------------------------------------------------------------------
  // ButtonSize variants
  // ---------------------------------------------------------------------------
  group('ButtonSize variants', () {
    for (final size in ButtonSize.values) {
      testWidgets('size ${size.name} renders without throwing', (tester) async {
        await tester.pumpWidget(_wrap(CustomButton(
          text: 'Size ${size.name}',
          size: size,
          onPressed: () {},
        )));
        await tester.pump();
        expect(find.text('Size ${size.name}'), findsOneWidget);
      });
    }
  });

  // ---------------------------------------------------------------------------
  // isLoading
  // ---------------------------------------------------------------------------
  group('isLoading', () {
    testWidgets('isLoading=true shows CircularProgressIndicator, no text',
        (tester) async {
      await tester.pumpWidget(_wrap(const CustomButton(
        text: 'Submit',
        isLoading: true,
        onPressed: null,
      )));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('isLoading=false (default) shows text', (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Submit',
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // isDisabled
  // ---------------------------------------------------------------------------
  group('isDisabled', () {
    testWidgets('isDisabled=true: tapping does NOT call onPressed',
        (tester) async {
      int callCount = 0;
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Disabled',
        isDisabled: true,
        onPressed: () => callCount++,
      )));
      await tester.pump();
      await tester.tap(find.byType(CustomButton));
      await tester.pump();
      expect(callCount, equals(0));
    });

    testWidgets('isDisabled=false (default): tapping calls onPressed',
        (tester) async {
      int callCount = 0;
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Enabled',
        onPressed: () => callCount++,
      )));
      await tester.pump();
      await tester.tap(find.text('Enabled'));
      await tester.pump();
      expect(callCount, equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // leadingIcon / trailingIcon
  // ---------------------------------------------------------------------------
  group('leadingIcon and trailingIcon', () {
    testWidgets('leadingIcon appears in tree', (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'With Leading',
        leadingIcon: Icons.coffee,
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.byIcon(Icons.coffee), findsOneWidget);
      expect(find.text('With Leading'), findsOneWidget);
    });

    testWidgets('trailingIcon appears in tree', (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'With Trailing',
        trailingIcon: Icons.arrow_forward,
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.text('With Trailing'), findsOneWidget);
    });

    testWidgets('both leadingIcon and trailingIcon appear', (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Both Icons',
        leadingIcon: Icons.coffee,
        trailingIcon: Icons.arrow_forward,
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.byIcon(Icons.coffee), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.text('Both Icons'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // isFullWidth
  // ---------------------------------------------------------------------------
  group('isFullWidth', () {
    testWidgets('isFullWidth=true wraps in SizedBox with infinite width',
        (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Full Width',
        isFullWidth: true,
        onPressed: () {},
      )));
      await tester.pump();
      // A SizedBox with width == double.infinity should be in the tree
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final hasInfiniteWidth =
          sizedBoxes.any((box) => box.width == double.infinity);
      expect(hasInfiniteWidth, isTrue);
    });

    testWidgets('isFullWidth=false (default): button still renders',
        (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Not Full Width',
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.text('Not Full Width'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Custom backgroundColor / textColor
  // ---------------------------------------------------------------------------
  group('custom colors', () {
    testWidgets('custom backgroundColor renders without throwing',
        (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Custom BG',
        backgroundColor: Colors.teal,
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.text('Custom BG'), findsOneWidget);
    });

    testWidgets('custom textColor renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Custom Text Color',
        textColor: Colors.orange,
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.text('Custom Text Color'), findsOneWidget);
    });

    testWidgets('both custom backgroundColor and textColor render without throwing',
        (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Custom Both',
        backgroundColor: Colors.indigo,
        textColor: Colors.yellow,
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.text('Custom Both'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // onPressed=null (disabled state via null callback)
  // ---------------------------------------------------------------------------
  group('onPressed=null', () {
    testWidgets('button renders without throwing when onPressed is null',
        (tester) async {
      await tester.pumpWidget(_wrap(const CustomButton(
        text: 'No Press',
        onPressed: null,
      )));
      await tester.pump();
      expect(find.text('No Press'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Underlying button widget types
  // ---------------------------------------------------------------------------
  group('underlying button widget types', () {
    testWidgets('primary type uses ElevatedButton', (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Primary',
        type: ButtonType.primary,
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('secondary type uses ElevatedButton', (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Secondary',
        type: ButtonType.secondary,
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('danger type uses ElevatedButton', (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Danger',
        type: ButtonType.danger,
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('success type uses ElevatedButton', (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Success',
        type: ButtonType.success,
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('outlined type uses OutlinedButton', (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Outlined',
        type: ButtonType.outlined,
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('text type uses TextButton', (tester) async {
      await tester.pumpWidget(_wrap(CustomButton(
        text: 'Text',
        type: ButtonType.text,
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.byType(TextButton), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // CustomButton isLoading loading color variants
  // ---------------------------------------------------------------------------
  group('CustomButton loading color variants', () {
    for (final type in ButtonType.values) {
      testWidgets('isLoading=true for ${type.name} shows spinner', (tester) async {
        await tester.pumpWidget(_wrap(CustomButton(
          text: 'Loading',
          type: type,
          isLoading: true,
          onPressed: () {},
        )));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    }
  });

  // ---------------------------------------------------------------------------
  // CustomIconButton
  // ---------------------------------------------------------------------------
  group('CustomIconButton', () {
    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(_wrap(CustomIconButton(icon: Icons.add)));
      await tester.pump();
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(
        CustomIconButton(icon: Icons.add, onPressed: () => called = true),
      ));
      await tester.pump();
      await tester.tap(find.byType(CustomIconButton));
      expect(called, isTrue);
    });

    testWidgets('does not call onPressed when isLoading=true', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(
        CustomIconButton(
          icon: Icons.add,
          onPressed: () => called = true,
          isLoading: true,
        ),
      ));
      await tester.pump();
      await tester.tap(find.byType(CustomIconButton), warnIfMissed: false);
      expect(called, isFalse);
    });

    testWidgets('shows spinner when isLoading=true', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomIconButton(icon: Icons.add, isLoading: true),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('applies custom size', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomIconButton(icon: Icons.add, size: 64.0),
      ));
      await tester.pump();
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(IconButton),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.constraints?.maxWidth, 64.0);
    });

    testWidgets('shows tooltip when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomIconButton(icon: Icons.add, tooltip: 'Add item'),
      ));
      await tester.pump();
      expect(find.byType(CustomIconButton), findsOneWidget);
    });

    testWidgets('renders with custom iconColor', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomIconButton(icon: Icons.star, iconColor: Colors.red),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders with custom backgroundColor', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomIconButton(icon: Icons.star, backgroundColor: Colors.blue),
      ));
      await tester.pump();
      expect(find.byType(CustomIconButton), findsOneWidget);
    });

    testWidgets('renders without onPressed (null)', (tester) async {
      await tester.pumpWidget(_wrap(
        const CustomIconButton(icon: Icons.close),
      ));
      await tester.pump();
      expect(find.byType(CustomIconButton), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // CustomFloatingButton
  // ---------------------------------------------------------------------------
  group('CustomFloatingButton', () {
    testWidgets('renders standard FAB with icon', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomFloatingButton(icon: Icons.add, onPressed: () {}),
      ));
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders extended FAB with label', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomFloatingButton(
          icon: Icons.add,
          label: 'Add',
          isExtended: true,
          onPressed: () {},
        ),
      ));
      await tester.pump();
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('shows spinner when isLoading=true', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomFloatingButton(icon: Icons.add, isLoading: true, onPressed: () {}),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows spinner in extended FAB when isLoading=true', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomFloatingButton(
          icon: Icons.add,
          label: 'Add',
          isExtended: true,
          isLoading: true,
          onPressed: () {},
        ),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(
        CustomFloatingButton(icon: Icons.add, onPressed: () => called = true),
      ));
      await tester.pump();
      await tester.tap(find.byType(FloatingActionButton));
      expect(called, isTrue);
    });
  });
}
