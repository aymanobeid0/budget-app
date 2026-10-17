import 'package:equatable/equatable.dart';

import '../expenses/expense.dart';
import 'income.dart';

/// The stretch of time a Net covers.
enum NetPeriod { week, month, allTime }

/// "This week" starts on Monday (confirmed by the user, 2026-10-17).
const netWeekStart = DateTime.monday;

/// Income, Expenses and their difference for one period (GLOSSARY.md: Net),
/// all in minor units.
class NetSummary extends Equatable {
  const NetSummary({required this.incomeMinor, required this.expensesMinor});

  final int incomeMinor;
  final int expensesMinor;

  int get netMinor => incomeMinor - expensesMinor;
  bool get isNegative => netMinor < 0;

  @override
  List<Object?> get props => [incomeMinor, expensesMinor];
}

/// Net for [period] as seen on [today]. Deleted entries never count.
///
/// Dates compare as calendar days, the way paid-on and spent-on dates are
/// stored, so time of day and time zone never move an entry across a
/// boundary.
NetSummary calculateNet({
  required List<Income> income,
  required List<Expense> expenses,
  required NetPeriod period,
  required DateTime today,
  int weekStart = netWeekStart,
}) {
  final day = _day(today);
  final bool Function(DateTime) inPeriod = switch (period) {
    NetPeriod.allTime => (_) => true,
    NetPeriod.month => (d) => d.year == day.year && d.month == day.month,
    NetPeriod.week => () {
        final start = day.subtract(Duration(days: (day.weekday - weekStart) % 7));
        final end = start.add(const Duration(days: 6));
        return (DateTime d) => !d.isBefore(start) && !d.isAfter(end);
      }(),
  };

  var incomeMinor = 0;
  for (final i in income) {
    if (i.deletedAt == null && inPeriod(_day(i.paidOn))) incomeMinor += i.amountMinor;
  }
  var expensesMinor = 0;
  for (final e in expenses) {
    if (e.deletedAt == null && inPeriod(_day(e.spentOn))) expensesMinor += e.amountMinor;
  }
  return NetSummary(incomeMinor: incomeMinor, expensesMinor: expensesMinor);
}

DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);
