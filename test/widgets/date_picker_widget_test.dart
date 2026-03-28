import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/presentation/widgets/common/date_picker_widget.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('DatePickerWidget', () {
    testWidgets('renders hint text when no date selected', (tester) async {
      await tester.pumpWidget(_wrap(const DatePickerWidget()));
      expect(find.text('Select date'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders custom hint text', (tester) async {
      await tester.pumpWidget(_wrap(const DatePickerWidget(hintText: 'Pick a date')));
      expect(find.text('Pick a date'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders formatted date when selectedDate is provided', (tester) async {
      final date = DateTime(2024, 6, 15);
      await tester.pumpWidget(_wrap(DatePickerWidget(selectedDate: date)));
      expect(find.text('15/06/2024'), findsOneWidget);
    });

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(const DatePickerWidget(labelText: 'Harvest Date')));
      expect(find.text('Harvest Date'), findsOneWidget);
    });

    testWidgets('renders required label with asterisk', (tester) async {
      await tester.pumpWidget(_wrap(const DatePickerWidget(
        labelText: 'Date',
        isRequired: true,
      )));
      expect(find.text('Date *'), findsOneWidget);
    });

    testWidgets('renders helper text', (tester) async {
      await tester.pumpWidget(_wrap(const DatePickerWidget(
        helperText: 'Choose a date in the past',
      )));
      expect(find.text('Choose a date in the past'), findsOneWidget);
    });

    testWidgets('renders error text', (tester) async {
      await tester.pumpWidget(_wrap(const DatePickerWidget(
        errorText: 'Date is required',
      )));
      expect(find.text('Date is required'), findsOneWidget);
    });

    testWidgets('renders calendar icon by default', (tester) async {
      await tester.pumpWidget(_wrap(const DatePickerWidget()));
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('renders custom prefix icon', (tester) async {
      await tester.pumpWidget(_wrap(const DatePickerWidget(
        prefixIcon: Icons.event,
      )));
      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    testWidgets('no prefix icon when prefixIcon is null', (tester) async {
      await tester.pumpWidget(_wrap(const DatePickerWidget(prefixIcon: null)));
      expect(find.byIcon(Icons.calendar_today), findsNothing);
    });

    testWidgets('uses custom date format function', (tester) async {
      final date = DateTime(2024, 6, 15);
      await tester.pumpWidget(_wrap(DatePickerWidget(
        selectedDate: date,
        dateFormat: (d) => '${d.year}-${d.month}-${d.day}',
      )));
      expect(find.text('2024-6-15'), findsOneWidget);
    });

    testWidgets('disabled widget does not respond to taps', (tester) async {
      DateTime? changed;
      await tester.pumpWidget(_wrap(DatePickerWidget(
        enabled: false,
        onDateChanged: (d) => changed = d,
      )));
      await tester.tap(find.byType(DatePickerWidget));
      await tester.pump();
      expect(changed, isNull);
    });

    testWidgets('tapping opens date picker dialog', (tester) async {
      await tester.pumpWidget(_wrap(const DatePickerWidget()));
      await tester.tap(find.byType(DatePickerWidget));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('tapping OK calls onDateChanged', (tester) async {
      DateTime? changed;
      await tester.pumpWidget(_wrap(DatePickerWidget(
        selectedDate: DateTime(2024, 6, 15),
        onDateChanged: (d) => changed = d,
      )));
      await tester.tap(find.byType(DatePickerWidget));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(changed, isNotNull);
    });

    testWidgets('tapping Cancel does not call onDateChanged', (tester) async {
      DateTime? changed;
      await tester.pumpWidget(_wrap(DatePickerWidget(
        onDateChanged: (d) => changed = d,
      )));
      await tester.tap(find.byType(DatePickerWidget));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(changed, isNull);
    });

    testWidgets('clamps to lastDate when lastDate is in the past', (tester) async {
      // Triggers _clampDate "isAfter(max)" path
      await tester.pumpWidget(_wrap(DatePickerWidget(
        lastDate: DateTime(2000),
        onDateChanged: (_) {},
      )));
      await tester.tap(find.byType(DatePickerWidget));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('clamps to firstDate when firstDate is in the future',
        (tester) async {
      // Triggers _clampDate "isBefore(min)" path
      await tester.pumpWidget(_wrap(DatePickerWidget(
        firstDate: DateTime(2200),
        lastDate: DateTime(2201),
        onDateChanged: (_) {},
      )));
      await tester.tap(find.byType(DatePickerWidget));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });
  });

  group('DateRangePickerWidget', () {
    testWidgets('renders hint text when no range selected', (tester) async {
      await tester.pumpWidget(_wrap(const DateRangePickerWidget()));
      expect(find.text('Select date range'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(const DateRangePickerWidget(labelText: 'Period')));
      expect(find.text('Period'), findsOneWidget);
    });

    testWidgets('renders required label with asterisk', (tester) async {
      await tester.pumpWidget(_wrap(const DateRangePickerWidget(
        labelText: 'Period',
        isRequired: true,
      )));
      expect(find.text('Period *'), findsOneWidget);
    });

    testWidgets('renders formatted range when selected', (tester) async {
      final range = DateTimeRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      await tester.pumpWidget(_wrap(DateRangePickerWidget(selectedRange: range)));
      expect(find.text('01/01/2024 - 31/01/2024'), findsOneWidget);
    });

    testWidgets('renders error text', (tester) async {
      await tester.pumpWidget(_wrap(const DateRangePickerWidget(
        errorText: 'Range required',
      )));
      expect(find.text('Range required'), findsOneWidget);
    });

    testWidgets('uses custom date format function', (tester) async {
      final range = DateTimeRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      await tester.pumpWidget(_wrap(DateRangePickerWidget(
        selectedRange: range,
        dateFormat: (d) => '${d.year}',
      )));
      expect(find.text('2024 - 2024'), findsOneWidget);
    });

    testWidgets('uses custom separator', (tester) async {
      final range = DateTimeRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      await tester.pumpWidget(_wrap(DateRangePickerWidget(
        selectedRange: range,
        separator: ' to ',
      )));
      expect(find.textContaining(' to '), findsOneWidget);
    });

    testWidgets('disabled does not respond to taps', (tester) async {
      DateTimeRange? changed;
      await tester.pumpWidget(_wrap(DateRangePickerWidget(
        enabled: false,
        onRangeChanged: (r) => changed = r,
      )));
      await tester.tap(find.byType(DateRangePickerWidget));
      await tester.pump();
      expect(changed, isNull);
    });

    testWidgets('tapping opens date range picker dialog', (tester) async {
      await tester.pumpWidget(_wrap(const DateRangePickerWidget()));
      await tester.tap(find.byType(DateRangePickerWidget));
      await tester.pumpAndSettle();
      // DateRangePicker dialog is open — check for Save button
      expect(find.text('Save'), findsOneWidget);
      // Dismiss by pressing back
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();
    });
  });

  group('TimePickerWidget', () {
    testWidgets('renders hint text when no time selected', (tester) async {
      await tester.pumpWidget(_wrap(const TimePickerWidget()));
      expect(find.text('Select time'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(const TimePickerWidget(labelText: 'Meeting Time')));
      expect(find.text('Meeting Time'), findsOneWidget);
    });

    testWidgets('renders required label with asterisk', (tester) async {
      await tester.pumpWidget(_wrap(const TimePickerWidget(
        labelText: 'Time',
        isRequired: true,
      )));
      expect(find.text('Time *'), findsOneWidget);
    });

    testWidgets('renders formatted time in 12-hour format', (tester) async {
      const time = TimeOfDay(hour: 14, minute: 30);
      await tester.pumpWidget(_wrap(TimePickerWidget(selectedTime: time)));
      expect(find.text('02:30 PM'), findsOneWidget);
    });

    testWidgets('renders formatted time in 24-hour format', (tester) async {
      const time = TimeOfDay(hour: 14, minute: 30);
      await tester.pumpWidget(_wrap(TimePickerWidget(
        selectedTime: time,
        use24HourFormat: true,
      )));
      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('renders midnight as 12:00 AM', (tester) async {
      const time = TimeOfDay(hour: 0, minute: 0);
      await tester.pumpWidget(_wrap(TimePickerWidget(selectedTime: time)));
      expect(find.text('12:00 AM'), findsOneWidget);
    });

    testWidgets('renders error text', (tester) async {
      await tester.pumpWidget(_wrap(const TimePickerWidget(
        errorText: 'Time required',
      )));
      expect(find.text('Time required'), findsOneWidget);
    });

    testWidgets('renders clock icon by default', (tester) async {
      await tester.pumpWidget(_wrap(const TimePickerWidget()));
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('disabled does not respond to taps', (tester) async {
      TimeOfDay? changed;
      await tester.pumpWidget(_wrap(TimePickerWidget(
        enabled: false,
        onTimeChanged: (t) => changed = t,
      )));
      await tester.tap(find.byType(TimePickerWidget));
      await tester.pump();
      expect(changed, isNull);
    });

    testWidgets('tapping opens time picker dialog', (tester) async {
      await tester.pumpWidget(_wrap(const TimePickerWidget()));
      await tester.tap(find.byType(TimePickerWidget));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('tapping OK calls onTimeChanged', (tester) async {
      TimeOfDay? changed;
      await tester.pumpWidget(_wrap(TimePickerWidget(
        selectedTime: const TimeOfDay(hour: 9, minute: 0),
        onTimeChanged: (t) => changed = t,
      )));
      await tester.tap(find.byType(TimePickerWidget));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(changed, isNotNull);
    });
  });

  group('DateTimePickerWidget', () {
    testWidgets('renders hint text when no datetime selected', (tester) async {
      await tester.pumpWidget(_wrap(const DateTimePickerWidget()));
      expect(find.text('Select date and time'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(const DateTimePickerWidget(labelText: 'Event Time')));
      expect(find.text('Event Time'), findsOneWidget);
    });

    testWidgets('renders required label with asterisk', (tester) async {
      await tester.pumpWidget(_wrap(const DateTimePickerWidget(
        labelText: 'Time',
        isRequired: true,
      )));
      expect(find.text('Time *'), findsOneWidget);
    });

    testWidgets('renders formatted datetime in 12-hour format', (tester) async {
      final dt = DateTime(2024, 6, 15, 14, 30);
      await tester.pumpWidget(_wrap(DateTimePickerWidget(selectedDateTime: dt)));
      expect(find.text('15/06/2024 02:30 PM'), findsOneWidget);
    });

    testWidgets('renders formatted datetime in 24-hour format', (tester) async {
      final dt = DateTime(2024, 6, 15, 14, 30);
      await tester.pumpWidget(_wrap(DateTimePickerWidget(
        selectedDateTime: dt,
        use24HourFormat: true,
      )));
      expect(find.text('15/06/2024 14:30'), findsOneWidget);
    });

    testWidgets('renders midnight correctly', (tester) async {
      final dt = DateTime(2024, 6, 15, 0, 0);
      await tester.pumpWidget(_wrap(DateTimePickerWidget(selectedDateTime: dt)));
      expect(find.text('15/06/2024 12:00 AM'), findsOneWidget);
    });

    testWidgets('renders error text', (tester) async {
      await tester.pumpWidget(_wrap(const DateTimePickerWidget(
        errorText: 'DateTime required',
      )));
      expect(find.text('DateTime required'), findsOneWidget);
    });

    testWidgets('renders event icon', (tester) async {
      await tester.pumpWidget(_wrap(const DateTimePickerWidget()));
      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    testWidgets('disabled does not respond to taps', (tester) async {
      DateTime? changed;
      await tester.pumpWidget(_wrap(DateTimePickerWidget(
        enabled: false,
        onDateTimeChanged: (dt) => changed = dt,
      )));
      await tester.tap(find.byType(DateTimePickerWidget));
      await tester.pump();
      expect(changed, isNull);
    });

    testWidgets('tapping opens date picker then time picker dialogs',
        (tester) async {
      await tester.pumpWidget(_wrap(const DateTimePickerWidget()));
      await tester.tap(find.byType(DateTimePickerWidget));
      await tester.pumpAndSettle();
      // First: date picker
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      // Second: time picker
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('cancelling date picker does not open time picker',
        (tester) async {
      DateTime? changed;
      await tester.pumpWidget(_wrap(DateTimePickerWidget(
        onDateTimeChanged: (dt) => changed = dt,
      )));
      await tester.tap(find.byType(DateTimePickerWidget));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(changed, isNull);
    });

    testWidgets('completing both pickers calls onDateTimeChanged', (tester) async {
      DateTime? changed;
      await tester.pumpWidget(_wrap(DateTimePickerWidget(
        selectedDateTime: DateTime(2024, 6, 15, 10, 30),
        onDateTimeChanged: (dt) => changed = dt,
      )));
      await tester.tap(find.byType(DateTimePickerWidget));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // date OK
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // time OK
      await tester.pumpAndSettle();
      expect(changed, isNotNull);
    });
  });
}
