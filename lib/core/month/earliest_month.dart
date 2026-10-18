import 'calendar_month.dart';

/// The month of the earliest of [dates]: as far back as Home and the Income
/// tab can step. Callers pass the spent-on and paid-on dates of their
/// non-deleted entries. Null when there are none.
CalendarMonth? earliestMonth(Iterable<DateTime> dates) {
  CalendarMonth? earliest;
  for (final day in dates) {
    final month = CalendarMonth.of(day);
    if (earliest == null || month.isBefore(earliest)) earliest = month;
  }
  return earliest;
}
