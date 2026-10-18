import 'package:budget_app/core/month/calendar_month.dart';
import 'package:budget_app/features/expenses/expense.dart';
import 'package:budget_app/features/income/income.dart';
import 'package:budget_app/features/income/earliest_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final stamp = DateTime(2026, 1, 1);

  Income income(DateTime paidOn, {bool deleted = false}) => Income(
        id: 'i${paidOn.month}${paidOn.day}',
        amountMinor: 1000,
        sourceId: 'src_salary',
        paidOn: DateTime.utc(paidOn.year, paidOn.month, paidOn.day),
        createdAt: stamp,
        updatedAt: stamp,
        deletedAt: deleted ? stamp : null,
      );

  Expense expense(DateTime spentOn, {bool deleted = false}) => Expense(
        id: 'e${spentOn.month}${spentOn.day}',
        amountMinor: 500,
        categoryId: 'cat_food',
        spentOn: DateTime.utc(spentOn.year, spentOn.month, spentOn.day),
        createdAt: stamp,
        updatedAt: stamp,
        deletedAt: deleted ? stamp : null,
      );

  test('is the month of the earliest Expense or Income, whichever came first', () {
    expect(
      earliestEntryMonth(
        expenses: [expense(DateTime(2026, 9, 3)), expense(DateTime(2026, 2, 28))],
        income: [income(DateTime(2026, 3, 1))],
      ),
      const CalendarMonth(2026, 2),
    );
    expect(
      earliestEntryMonth(
        expenses: [expense(DateTime(2026, 1, 15))],
        income: [income(DateTime(2025, 12, 31))],
      ),
      const CalendarMonth(2025, 12),
    );
  });

  test('ignores deleted entries', () {
    expect(
      earliestEntryMonth(
        expenses: [expense(DateTime(2025, 5, 1), deleted: true), expense(DateTime(2026, 8, 1))],
        income: [income(DateTime(2025, 6, 1), deleted: true)],
      ),
      const CalendarMonth(2026, 8),
    );
  });

  test('is null with no entries, or only deleted ones', () {
    expect(earliestEntryMonth(expenses: const [], income: const []), isNull);
    expect(
      earliestEntryMonth(expenses: [expense(DateTime(2026, 4, 1), deleted: true)], income: const []),
      isNull,
    );
  });
}
