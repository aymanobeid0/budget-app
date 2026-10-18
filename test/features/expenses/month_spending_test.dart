import 'package:budget_app/core/format/money.dart';
import 'package:budget_app/core/month/calendar_month.dart';
import 'package:budget_app/features/expenses/expense.dart';
import 'package:budget_app/features/expenses/month_spending.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final stamp = DateTime(2026, 1, 1);
  var n = 0;

  Expense expense(int amountMinor, DateTime spentOn, {bool deleted = false}) => Expense(
        id: 'e${n++}',
        amountMinor: amountMinor,
        categoryId: 'cat_food',
        spentOn: DateTime.utc(spentOn.year, spentOn.month, spentOn.day),
        createdAt: stamp,
        updatedAt: stamp,
        deletedAt: deleted ? stamp : null,
      );

  final today = DateTime(2026, 10, 18);

  group('summarizeMonthSpending', () {
    test('returns the chosen month\'s total next to the previous month\'s', () {
      final summary = summarizeMonthSpending(
        expenses: [
          expense(30000, DateTime(2026, 10, 1)),
          expense(5000, DateTime(2026, 10, 18)),
          expense(12500, DateTime(2026, 9, 30)),
          expense(4000, DateTime(2026, 9, 1)),
          expense(99900, DateTime(2026, 8, 31)),
          expense(70000, DateTime(2026, 9, 15), deleted: true),
        ],
        month: const CalendarMonth(2026, 10),
      );

      expect(summary.totalMinor, 35000);
      expect(summary.previousTotalMinor, 16500);
    });

    test('January\'s previous month is December of the year before', () {
      final summary = summarizeMonthSpending(
        expenses: [
          expense(2000, DateTime(2026, 1, 3)),
          expense(7000, DateTime(2025, 12, 31)),
          expense(100, DateTime(2026, 12, 5)),
        ],
        month: const CalendarMonth(2026, 1),
      );

      expect(summary.totalMinor, 2000);
      expect(summary.previousTotalMinor, 7000);
    });
  });

  group('compareWithPreviousMonth', () {
    String? line(int total, int previous, {CalendarMonth month = const CalendarMonth(2026, 10)}) =>
        compareWithPreviousMonth(
          MonthSpending(month: month, totalMinor: total, previousTotalMinor: previous),
          currency: Currency.mru,
          today: today,
        );

    test('more than the month before', () {
      expect(line(250000, 170000), '800 MRU more than September');
    });

    test('less than the month before', () {
      expect(line(100050, 170000), '699.50 MRU less than September');
    });

    test('same as the month before', () {
      expect(line(170000, 170000), 'Same as September');
    });

    test('hidden when the month before has no Expenses', () {
      expect(line(170000, 0), isNull);
      expect(line(0, 0), isNull);
    });

    test('names December with its year when looking at January', () {
      expect(line(2000, 7000, month: const CalendarMonth(2026, 1)), '50 MRU less than December 2025');
    });

    test('uses the configured Currency', () {
      expect(
        compareWithPreviousMonth(
          const MonthSpending(month: CalendarMonth(2026, 10), totalMinor: 1550, previousTotalMinor: 1000),
          currency: Currency.usd,
          today: today,
        ),
        '5.50 USD more than September',
      );
    });
  });
}
