import 'package:budget_app/core/month/calendar_month.dart';
import 'package:budget_app/features/income/income.dart';
import 'package:budget_app/features/income/income_breakdown.dart';
import 'package:budget_app/features/income/income_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const october = CalendarMonth(2026, 10);
  final created = DateTime.utc(2026, 1, 1);

  Income income(String id, String sourceId, int amountMinor, DateTime paidOn, {bool deleted = false}) => Income(
        id: id,
        amountMinor: amountMinor,
        sourceId: sourceId,
        paidOn: paidOn,
        createdAt: created,
        updatedAt: created,
        deletedAt: deleted ? created : null,
      );

  IncomeSource source(String id, String name, {bool deleted = false}) => IncomeSource(
        id: id,
        name: name,
        icon: 'work',
        color: 0xFF10B981,
        createdAt: created,
        updatedAt: created,
        deletedAt: deleted ? created : null,
      );

  test('totals the month per Income Source, largest first, with each share', () {
    final rows = incomeSourceBreakdown(
      [
        income('a', 'src_salary', 60000, DateTime.utc(2026, 10, 1)),
        income('b', 'src_freelance', 20000, DateTime.utc(2026, 10, 12)),
        income('c', 'src_freelance', 20000, DateTime.utc(2026, 10, 31)),
        income('d', 'src_salary', 99900, DateTime.utc(2026, 9, 30)), // September
        income('e', 'src_salary', 50000, DateTime.utc(2026, 10, 2), deleted: true),
      ],
      month: october,
      sourceById: {'src_salary': source('src_salary', 'Salary'), 'src_freelance': source('src_freelance', 'Freelance')},
    );

    expect([for (final r in rows) (r.group.name, r.totalMinor, r.share)],
        [('Salary', 60000, 0.6), ('Freelance', 40000, 0.4)]);
  });

  test('Income from a deleted Income Source still shows under its name', () {
    final rows = incomeSourceBreakdown(
      [income('a', 'src_clinic', 30000, DateTime.utc(2026, 10, 5))],
      month: october,
      sourceById: {'src_clinic': source('src_clinic', 'Dental clinic', deleted: true)},
    );

    expect(rows.single.group.name, 'Dental clinic');
    expect(rows.single.group.color, const Color(0xFF10B981));
  });

  test('a source missing entirely shows as Unknown source, as its rows do', () {
    final rows = incomeSourceBreakdown(
      [income('a', 'src_gone', 30000, DateTime.utc(2026, 10, 5))],
      month: october,
      sourceById: const {},
    );

    expect(rows.single.group.name, 'Unknown source');
    expect(rows.single.group.icon, Icons.payments_rounded);
  });
}
