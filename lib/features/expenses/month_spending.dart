import 'package:equatable/equatable.dart';

import '../../core/format/money.dart';
import '../../core/month/calendar_month.dart';
import 'expense.dart';

/// What was spent in one calendar month and in the month before, in minor
/// units. On the current month [totalMinor] is the month so far.
class MonthSpending extends Equatable {
  const MonthSpending({required this.month, required this.totalMinor, required this.previousTotalMinor});

  final CalendarMonth month;
  final int totalMinor;
  final int previousTotalMinor;

  @override
  List<Object?> get props => [month, totalMinor, previousTotalMinor];
}

/// The total of [month]'s Expenses and of the month before. Deleted
/// Expenses never count, and dates compare as calendar days.
MonthSpending summarizeMonthSpending({required List<Expense> expenses, required CalendarMonth month}) {
  final previous = month.previous;
  var total = 0, previousTotal = 0;
  for (final e in expenses) {
    if (e.deletedAt != null) continue;
    if (month.contains(e.spentOn)) {
      total += e.amountMinor;
    } else if (previous.contains(e.spentOn)) {
      previousTotal += e.amountMinor;
    }
  }
  return MonthSpending(month: month, totalMinor: total, previousTotalMinor: previousTotal);
}

/// "800 MRU more than September", "50 MRU less than December 2025" or
/// "Same as September". Null when the month before has no Expenses, so the
/// card never says "more than 0".
String? compareWithPreviousMonth(MonthSpending spending, {required Currency currency, required DateTime today}) {
  if (spending.previousTotalMinor == 0) return null;
  final previous = spending.month.previous.label(today: today);
  final difference = spending.totalMinor - spending.previousTotalMinor;
  if (difference == 0) return 'Same as $previous';
  final amount = Money.withLabel(difference.abs(), currency);
  return difference > 0 ? '$amount more than $previous' : '$amount less than $previous';
}
