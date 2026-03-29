// test/widgets/confirmation_dialog_test.dart
//
// Widget tests for ConfirmationDialog, InfoDialog, and InputDialog.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/presentation/widgets/common/confirmation_dialog.dart';

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
  group('ConfirmationDialog', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConfirmationDialog(
          title: 'Delete item?',
          message: 'This cannot be undone.',
        ),
      ));
      await tester.pump();
      expect(find.text('Delete item?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
    });

    testWidgets('renders confirm and cancel buttons with defaults',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const ConfirmationDialog(
          title: 'Sure?',
          message: 'Msg',
        ),
      ));
      await tester.pump();
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('custom button texts applied', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConfirmationDialog(
          title: 'Sure?',
          message: 'Msg',
          confirmText: 'Yes',
          cancelText: 'No',
        ),
      ));
      await tester.pump();
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('onConfirm called when confirm tapped', (tester) async {
      bool confirmed = false;
      await tester.pumpWidget(_wrap(
        ConfirmationDialog(
          title: 'Confirm?',
          message: 'Msg',
          onConfirm: () => confirmed = true,
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      expect(confirmed, isTrue);
    });

    testWidgets('onCancel called when cancel tapped', (tester) async {
      bool cancelled = false;
      await tester.pumpWidget(_wrap(
        ConfirmationDialog(
          title: 'Confirm?',
          message: 'Msg',
          onCancel: () => cancelled = true,
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(cancelled, isTrue);
    });

    testWidgets('renders each dialog type without throwing', (tester) async {
      for (final type in ConfirmationDialogType.values) {
        await tester.pumpWidget(_wrap(
          ConfirmationDialog(
            title: type.name,
            message: 'Message',
            type: type,
          ),
        ));
        await tester.pump();
        expect(find.text(type.name), findsOneWidget);
      }
    });

    testWidgets('hides icon when showIcon is false', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConfirmationDialog(
          title: 'Title',
          message: 'Msg',
          showIcon: false,
        ),
      ));
      await tester.pump();
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('shows custom icon when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConfirmationDialog(
          title: 'Title',
          message: 'Msg',
          icon: Icons.star,
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders additionalContent when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConfirmationDialog(
          title: 'Title',
          message: 'Msg',
          additionalContent: Text('Extra info'),
        ),
      ));
      await tester.pump();
      expect(find.text('Extra info'), findsOneWidget);
    });

    testWidgets('danger type shows danger icon style', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConfirmationDialog(
          title: 'Delete?',
          message: 'Cannot undo.',
          type: ConfirmationDialogType.danger,
        ),
      ));
      await tester.pump();
      expect(find.text('Delete?'), findsOneWidget);
    });
  });

  group('ConfirmationDialog.show() static helper', () {
    testWidgets('opens dialog via show()', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => ConfirmationDialog.show(
                context: context,
                title: 'Shown?',
                message: 'Via show()',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Shown?'), findsOneWidget);
      expect(find.text('Via show()'), findsOneWidget);
    });

    testWidgets('showDelete() opens delete dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  ConfirmationDialog.showDelete(context: context, itemName: 'record'),
              child: const Text('Delete'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete record?'), findsOneWidget);
    });

    testWidgets('showDiscardChanges() opens discard dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  ConfirmationDialog.showDiscardChanges(context: context),
              child: const Text('Discard'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
    });

    testWidgets('showLogout() opens logout dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  ConfirmationDialog.showLogout(context: context),
              child: const Text('Logout'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOneWidget);
    });
  });

  group('InfoDialog', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(_wrap(
        const InfoDialog(title: 'Info', message: 'Here is some info.'),
      ));
      await tester.pump();
      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Here is some info.'), findsOneWidget);
    });

    testWidgets('renders OK button by default', (tester) async {
      await tester.pumpWidget(_wrap(
        const InfoDialog(title: 'Info', message: 'Msg'),
      ));
      await tester.pump();
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('custom button text applied', (tester) async {
      await tester.pumpWidget(_wrap(
        const InfoDialog(title: 'Info', message: 'Msg', buttonText: 'Got it'),
      ));
      await tester.pump();
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('shows icon when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const InfoDialog(
          title: 'Info',
          message: 'Msg',
          icon: Icons.info_outline,
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('no icon when not provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const InfoDialog(title: 'Info', message: 'Msg'),
      ));
      await tester.pump();
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('InputDialog', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(_wrap(
        const InputDialog(title: 'Enter name'),
      ));
      await tester.pump();
      expect(find.text('Enter name'), findsOneWidget);
    });

    testWidgets('renders message when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const InputDialog(
          title: 'Name',
          message: 'Please enter your name.',
        ),
      ));
      await tester.pump();
      expect(find.text('Please enter your name.'), findsOneWidget);
    });

    testWidgets('renders hint text', (tester) async {
      await tester.pumpWidget(_wrap(
        const InputDialog(title: 'Input', hintText: 'Type here...'),
      ));
      await tester.pump();
      expect(find.text('Type here...'), findsOneWidget);
    });

    testWidgets('confirm and cancel buttons present', (tester) async {
      await tester.pumpWidget(_wrap(const InputDialog(title: 'Input')));
      await tester.pump();
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows initial value in text field', (tester) async {
      await tester.pumpWidget(_wrap(
        const InputDialog(title: 'Edit', initialValue: 'existing text'),
      ));
      await tester.pump();
      expect(find.text('existing text'), findsOneWidget);
    });

    testWidgets('validator shows error on invalid input', (tester) async {
      await tester.pumpWidget(_wrap(
        InputDialog(
          title: 'Input',
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('typing clears validation error', (tester) async {
      await tester.pumpWidget(_wrap(
        InputDialog(
          title: 'Input',
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();
      expect(find.text('Required'), findsNothing);
    });

    testWidgets('InfoDialog.show() opens dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => InfoDialog.show(
                context: context,
                title: 'Static Info',
                message: 'Via static show()',
              ),
              child: const Text('Open Info'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open Info'));
      await tester.pumpAndSettle();
      expect(find.text('Static Info'), findsOneWidget);
    });
  });
}
