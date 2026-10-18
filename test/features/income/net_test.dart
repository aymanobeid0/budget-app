import 'package:budget_app/core/month/calendar_month.dart';
import 'package:budget_app/features/expenses/expense.dart';
import 'package:budget_app/features/income/income.dart';
import 'package:budget_app/features/income/net.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Monday 12 October 2026 starts the week; Wednesday the 14th is "today".
  final wednesday = DateTime(2026, 10, 14);
  final stamp = DateTime(2026, 1, 1);

  Income income(int minor, DateTime paidOn, {bool deleted = false}) => Income(
        id: 'i$minor${paidOn.day}',
        amountMinor: minor,
        sourceId: 'src_salary',
        paidOn: DateTime.utc(paidOn.year, paidOn.month, paidOn.day),
        createdAt: stamp,
        updatedAt: stamp,
        deletedAt: deleted ? stamp : null,
      );

  Expense expense(int minor, DateTime spentOn, {bool deleted = false}) => Expense(
        id: 'e$minor${spentOn.day}',
        amountMinor: minor,
        categoryId: 'cat_food',
        spentOn: DateTime.utc(spentOn.year, spentOn.month, spentOn.day),
        createdAt: stamp,
        updatedAt: stamp,
        deletedAt: deleted ? stamp : null,
      );

  test('the week runs Monday to Sunday', () {
    final net = calculateNet(
      income: [
        income(1000, DateTime(2026, 10, 11)), // Sunday before: out
        income(2000, DateTime(2026, 10, 12)), // Monday: in
        income(4000, DateTime(2026, 10, 18)), // Sunday: in
        income(8000, DateTime(2026, 10, 19)), // next Monday: out
      ],
      expenses: [expense(500, DateTime(2026, 10, 13))],
      period: NetPeriod.week,
      today: wednesday,
    );

    expect(net.incomeMinor, 6000);
    expect(net.expensesMinor, 500);
    expect(net.netMinor, 5500);
  });

  test('on a Monday the week starts that day; on a Sunday it started six days before', () {
    final entries = [income(100, DateTime(2026, 10, 11)), income(200, DateTime(2026, 10, 12))];

    final monday = calculateNet(income: entries, expenses: const [], period: NetPeriod.week, today: DateTime(2026, 10, 12));
    final sunday = calculateNet(income: entries, expenses: const [], period: NetPeriod.week, today: DateTime(2026, 10, 18));
    final prevSunday =
        calculateNet(income: entries, expenses: const [], period: NetPeriod.week, today: DateTime(2026, 10, 11));

    expect(monday.incomeMinor, 200);
    expect(sunday.incomeMinor, 200);
    expect(prevSunday.incomeMinor, 100);
  });

  test('the month is the calendar month', () {
    final net = calculateNet(
      income: [
        income(1000, DateTime(2026, 9, 30)), // out
        income(2000, DateTime(2026, 10, 1)), // in
        income(4000, DateTime(2026, 10, 31)), // in
        income(8000, DateTime(2026, 11, 1)), // out
      ],
      expenses: [expense(300, DateTime(2026, 10, 31)), expense(700, DateTime(2025, 10, 5))],
      period: NetPeriod.month,
      today: wednesday,
    );

    expect(net.incomeMinor, 6000);
    expect(net.expensesMinor, 300);
  });

  test('all time counts everything', () {
    final net = calculateNet(
      income: [income(1000, DateTime(2020, 1, 1)), income(2000, DateTime(2026, 10, 14))],
      expenses: [expense(500, DateTime(2019, 5, 5))],
      period: NetPeriod.allTime,
      today: wednesday,
    );

    expect(net.netMinor, 2500);
  });

  test('spending more than you make gives a negative Net', () {
    final net = calculateNet(
      income: [income(1000, wednesday)],
      expenses: [expense(1500, wednesday)],
      period: NetPeriod.month,
      today: wednesday,
    );

    expect(net.netMinor, -500);
    expect(net.isNegative, isTrue);
  });

  test('deleted Income and Expenses are left out', () {
    final net = calculateNet(
      income: [income(1000, wednesday), income(9000, wednesday, deleted: true)],
      expenses: [expense(200, wednesday), expense(7000, wednesday, deleted: true)],
      period: NetPeriod.allTime,
      today: wednesday,
    );

    expect(net.incomeMinor, 1000);
    expect(net.expensesMinor, 200);
  });

  test('Net for a past month counts only that calendar month, across a year boundary', () {
    final net = calculateNetForMonth(
      income: [
        income(1000, DateTime(2025, 11, 30)), // November: out
        income(2000, DateTime(2025, 12, 1)), // in
        income(4000, DateTime(2025, 12, 31)), // in
        income(8000, DateTime(2026, 1, 1)), // January: out
      ],
      expenses: [
        expense(500, DateTime(2025, 12, 15)), // in
        expense(700, DateTime(2026, 10, 14)), // this month: out
      ],
      month: const CalendarMonth(2025, 12),
    );

    expect(net.incomeMinor, 6000);
    expect(net.expensesMinor, 500);
    expect(net.netMinor, 5500);
  });

  test('Net for a past month leaves out deleted Income and Expenses', () {
    final august = DateTime(2026, 8, 10);
    final net = calculateNetForMonth(
      income: [income(1000, august), income(9000, august, deleted: true)],
      expenses: [expense(1500, august), expense(7000, august, deleted: true)],
      month: const CalendarMonth(2026, 8),
    );

    expect(net.incomeMinor, 1000);
    expect(net.expensesMinor, 1500);
    expect(net.netMinor, -500);
  });
}
