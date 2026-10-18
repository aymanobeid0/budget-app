import '../../core/month/calendar_month.dart';
import '../expenses/expense.dart';
import 'income.dart';

/// The month of the earliest non-deleted Expense or Income: as far back as
/// Home and the Income tab can step. Null when there are no entries.
CalendarMonth? earliestEntryMonth({required List<Expense> expenses, required List<Income> income}) {
  CalendarMonth? earliest;
  void consider(DateTime day) {
    final month = CalendarMonth.of(day);
    if (earliest == null || month.isBefore(earliest!)) earliest = month;
  }

  for (final e in expenses) {
    if (e.deletedAt == null) consider(e.spentOn);
  }
  for (final i in income) {
    if (i.deletedAt == null) consider(i.paidOn);
  }
  return earliest;
}
