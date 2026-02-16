import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Date picker widget following Clean Architecture principles
/// Requirements: 1.5, 10.2, 16.1
class DatePickerWidget extends StatelessWidget {
  /// Currently selected date
  final DateTime? selectedDate;

  /// Callback when date changes
  final ValueChanged<DateTime>? onDateChanged;

  /// Label text displayed above the field
  final String? labelText;

  /// Hint text shown when no date is selected
  final String? hintText;

  /// Helper text shown below the field
  final String? helperText;

  /// Error text shown when validation fails
  final String? errorText;

  /// Minimum selectable date
  final DateTime? firstDate;

  /// Maximum selectable date
  final DateTime? lastDate;

  /// Initial date when picker opens (defaults to selectedDate or today)
  final DateTime? initialDate;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is required (shows asterisk)
  final bool isRequired;

  /// Custom date format function
  final String Function(DateTime)? dateFormat;

  /// Prefix icon
  final IconData? prefixIcon;

  /// Border radius override
  final double? borderRadius;

  /// Select entry mode (calendar, input, calendarOnly, inputOnly)
  final DatePickerEntryMode initialEntryMode;

  /// Help text shown in the date picker dialog
  final String? dialogHelpText;

  /// Cancel button text
  final String? cancelText;

  /// Confirm button text
  final String? confirmText;

  const DatePickerWidget({
    super.key,
    this.selectedDate,
    this.onDateChanged,
    this.labelText,
    this.hintText = 'Select date',
    this.helperText,
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.enabled = true,
    this.isRequired = false,
    this.dateFormat,
    this.prefixIcon = Icons.calendar_today,
    this.borderRadius,
    this.initialEntryMode = DatePickerEntryMode.calendar,
    this.dialogHelpText,
    this.cancelText,
    this.confirmText,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppTheme.borderRadiusMedium;

    return GestureDetector(
      onTap: enabled ? () => _showDatePicker(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: _buildLabelText(),
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          filled: true,
          fillColor: AppTheme.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.padding16,
            vertical: AppTheme.padding12,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: errorText != null
                      ? AppTheme.errorColor
                      : AppTheme.textSecondary,
                  size: AppTheme.iconSizeMedium,
                )
              : null,
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: AppTheme.textSecondary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(color: AppTheme.textHint),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(color: AppTheme.textHint),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(color: AppTheme.errorColor),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: BorderSide(color: AppTheme.textHint.withOpacity(0.5)),
          ),
          labelStyle: AppTheme.body.copyWith(color: AppTheme.textSecondary),
          hintStyle: AppTheme.body.copyWith(color: AppTheme.textHint),
          errorStyle: AppTheme.caption.copyWith(color: AppTheme.errorColor),
          helperStyle: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
        ),
        child: Text(
          _formatDate(selectedDate),
          style: AppTheme.body.copyWith(
            color: selectedDate != null
                ? AppTheme.textPrimary
                : AppTheme.textHint,
          ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final effectiveFirstDate = firstDate ?? DateTime(1900);
    final effectiveLastDate = lastDate ?? DateTime(2100);
    final effectiveInitialDate =
        initialDate ?? selectedDate ?? _clampDate(now, effectiveFirstDate, effectiveLastDate);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      initialEntryMode: initialEntryMode,
      helpText: dialogHelpText,
      cancelText: cancelText,
      confirmText: confirmText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.onPrimaryColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      onDateChanged?.call(pickedDate);
    }
  }

  DateTime _clampDate(DateTime date, DateTime min, DateTime max) {
    if (date.isBefore(min)) return min;
    if (date.isAfter(max)) return max;
    return date;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return hintText ?? 'Select date';
    if (dateFormat != null) return dateFormat!(date);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String? _buildLabelText() {
    if (labelText == null) return null;
    return isRequired ? '$labelText *' : labelText;
  }
}

/// Date range picker widget
class DateRangePickerWidget extends StatelessWidget {
  /// Currently selected date range
  final DateTimeRange? selectedRange;

  /// Callback when date range changes
  final ValueChanged<DateTimeRange>? onRangeChanged;

  /// Label text displayed above the field
  final String? labelText;

  /// Hint text shown when no range is selected
  final String? hintText;

  /// Error text shown when validation fails
  final String? errorText;

  /// Minimum selectable date
  final DateTime? firstDate;

  /// Maximum selectable date
  final DateTime? lastDate;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is required
  final bool isRequired;

  /// Custom date format function
  final String Function(DateTime)? dateFormat;

  /// Separator between start and end dates
  final String separator;

  const DateRangePickerWidget({
    super.key,
    this.selectedRange,
    this.onRangeChanged,
    this.labelText,
    this.hintText = 'Select date range',
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.isRequired = false,
    this.dateFormat,
    this.separator = ' - ',
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = AppTheme.borderRadiusMedium;

    return GestureDetector(
      onTap: enabled ? () => _showDateRangePicker(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: _buildLabelText(),
          hintText: hintText,
          errorText: errorText,
          filled: true,
          fillColor: AppTheme.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.padding16,
            vertical: AppTheme.padding12,
          ),
          prefixIcon: const Icon(
            Icons.date_range,
            color: AppTheme.textSecondary,
            size: AppTheme.iconSizeMedium,
          ),
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: AppTheme.textSecondary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(color: AppTheme.textHint),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(color: AppTheme.textHint),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(color: AppTheme.errorColor),
          ),
        ),
        child: Text(
          _formatRange(selectedRange),
          style: AppTheme.body.copyWith(
            color: selectedRange != null
                ? AppTheme.textPrimary
                : AppTheme.textHint,
          ),
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final effectiveFirstDate = firstDate ?? DateTime(1900);
    final effectiveLastDate = lastDate ?? DateTime(2100);

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      initialDateRange: selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.onPrimaryColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      onRangeChanged?.call(pickedRange);
    }
  }

  String _formatRange(DateTimeRange? range) {
    if (range == null) return hintText ?? 'Select date range';
    final startStr = _formatSingleDate(range.start);
    final endStr = _formatSingleDate(range.end);
    return '$startStr$separator$endStr';
  }

  String _formatSingleDate(DateTime date) {
    if (dateFormat != null) return dateFormat!(date);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String? _buildLabelText() {
    if (labelText == null) return null;
    return isRequired ? '$labelText *' : labelText;
  }
}

/// Time picker widget
class TimePickerWidget extends StatelessWidget {
  /// Currently selected time
  final TimeOfDay? selectedTime;

  /// Callback when time changes
  final ValueChanged<TimeOfDay>? onTimeChanged;

  /// Label text displayed above the field
  final String? labelText;

  /// Hint text shown when no time is selected
  final String? hintText;

  /// Error text shown when validation fails
  final String? errorText;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is required
  final bool isRequired;

  /// Whether to use 24-hour format
  final bool use24HourFormat;

  /// Prefix icon
  final IconData? prefixIcon;

  const TimePickerWidget({
    super.key,
    this.selectedTime,
    this.onTimeChanged,
    this.labelText,
    this.hintText = 'Select time',
    this.errorText,
    this.enabled = true,
    this.isRequired = false,
    this.use24HourFormat = false,
    this.prefixIcon = Icons.access_time,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = AppTheme.borderRadiusMedium;

    return GestureDetector(
      onTap: enabled ? () => _showTimePicker(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: _buildLabelText(),
          hintText: hintText,
          errorText: errorText,
          filled: true,
          fillColor: AppTheme.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.padding16,
            vertical: AppTheme.padding12,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: AppTheme.textSecondary,
                  size: AppTheme.iconSizeMedium,
                )
              : null,
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: AppTheme.textSecondary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(color: AppTheme.textHint),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(color: AppTheme.textHint),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(color: AppTheme.errorColor),
          ),
        ),
        child: Text(
          _formatTime(selectedTime),
          style: AppTheme.body.copyWith(
            color: selectedTime != null
                ? AppTheme.textPrimary
                : AppTheme.textHint,
          ),
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final now = TimeOfDay.now();

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.onPrimaryColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: use24HourFormat,
            ),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null) {
      onTimeChanged?.call(pickedTime);
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return hintText ?? 'Select time';

    if (use24HourFormat) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }

  String? _buildLabelText() {
    if (labelText == null) return null;
    return isRequired ? '$labelText *' : labelText;
  }
}

/// Combined date and time picker widget
class DateTimePickerWidget extends StatelessWidget {
  /// Currently selected date and time
  final DateTime? selectedDateTime;

  /// Callback when date/time changes
  final ValueChanged<DateTime>? onDateTimeChanged;

  /// Label text displayed above the field
  final String? labelText;

  /// Hint text shown when no date/time is selected
  final String? hintText;

  /// Error text shown when validation fails
  final String? errorText;

  /// Minimum selectable date
  final DateTime? firstDate;

  /// Maximum selectable date
  final DateTime? lastDate;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is required
  final bool isRequired;

  /// Whether to use 24-hour format for time
  final bool use24HourFormat;

  const DateTimePickerWidget({
    super.key,
    this.selectedDateTime,
    this.onDateTimeChanged,
    this.labelText,
    this.hintText = 'Select date and time',
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.isRequired = false,
    this.use24HourFormat = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = AppTheme.borderRadiusMedium;

    return GestureDetector(
      onTap: enabled ? () => _showDateTimePicker(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: _buildLabelText(),
          hintText: hintText,
          errorText: errorText,
          filled: true,
          fillColor: AppTheme.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.padding16,
            vertical: AppTheme.padding12,
          ),
          prefixIcon: const Icon(
            Icons.event,
            color: AppTheme.textSecondary,
            size: AppTheme.iconSizeMedium,
          ),
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: AppTheme.textSecondary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(color: AppTheme.textHint),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(color: AppTheme.textHint),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            borderSide: const BorderSide(color: AppTheme.errorColor),
          ),
        ),
        child: Text(
          _formatDateTime(selectedDateTime),
          style: AppTheme.body.copyWith(
            color: selectedDateTime != null
                ? AppTheme.textPrimary
                : AppTheme.textHint,
          ),
        ),
      ),
    );
  }

  Future<void> _showDateTimePicker(BuildContext context) async {
    final now = DateTime.now();
    final effectiveFirstDate = firstDate ?? DateTime(1900);
    final effectiveLastDate = lastDate ?? DateTime(2100);
    final initialDateTime = selectedDateTime ?? now;

    // First, pick the date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _clampDate(initialDateTime, effectiveFirstDate, effectiveLastDate),
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.onPrimaryColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    // Then, pick the time
    if (!context.mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.onPrimaryColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: use24HourFormat,
            ),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null) {
      final combinedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      onDateTimeChanged?.call(combinedDateTime);
    }
  }

  DateTime _clampDate(DateTime date, DateTime min, DateTime max) {
    if (date.isBefore(min)) return min;
    if (date.isAfter(max)) return max;
    return date;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return hintText ?? 'Select date and time';

    final dateStr =
        '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';

    String timeStr;
    if (use24HourFormat) {
      timeStr =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final period = dateTime.hour < 12 ? 'AM' : 'PM';
      timeStr =
          '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
    }

    return '$dateStr $timeStr';
  }

  String? _buildLabelText() {
    if (labelText == null) return null;
    return isRequired ? '$labelText *' : labelText;
  }
}
