import 'package:budget_app/core/month/breakdown.dart';
import 'package:budget_app/core/month/calendar_month.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Entry = ({String group, int amount, DateTime on, bool deleted});

Entry entry(String group, int amount, DateTime on, {bool deleted = false}) =>
    (group: group, amount: amount, on: on, deleted: deleted);

const _names = {'food': 'Food', 'rent': 'Rent', 'gym': 'Gym', 'books': 'Books'};

BreakdownGroup describe(String id) =>
    BreakdownGroup(id: id, name: _names[id] ?? id, icon: Icons.category_rounded, color: const Color(0xFF3B82F6));

List<BreakdownRow> run(List<Entry> entries, CalendarMonth month) => monthBreakdown<Entry>(
      entries,
      month: month,
      dateOf: (e) => e.on,
      groupOf: (e) => e.group,
      amountOf: (e) => e.amount,
      isDeleted: (e) => e.deleted,
      describe: describe,
    );

void main() {
  const october = CalendarMonth(2026, 10);

  test('totals the month per group, largest first, with each share of the month', () {
    final rows = run([
      entry('food', 3000, DateTime.utc(2026, 10, 2)),
      entry('rent', 6000, DateTime.utc(2026, 10, 1)),
      entry('food', 3000, DateTime.utc(2026, 10, 31)),
      entry('gym', 3000, DateTime.utc(2026, 10, 15)),
      entry('food', 9900, DateTime.utc(2026, 9, 30)), // September
      entry('rent', 9900, DateTime.utc(2026, 11, 1)), // November
    ], october);

    expect([for (final r in rows) (r.group.name, r.totalMinor)], [('Food', 6000), ('Rent', 6000), ('Gym', 3000)]);
    expect([for (final r in rows) r.share], [0.4, 0.4, 0.2]);
  });

  test('deleted entries don\'t count, in the rows or the shares', () {
    final rows = run([
      entry('food', 3000, DateTime.utc(2026, 10, 2)),
      entry('rent', 1000, DateTime.utc(2026, 10, 3)),
      entry('food', 5000, DateTime.utc(2026, 10, 4), deleted: true),
      entry('gym', 7000, DateTime.utc(2026, 10, 5), deleted: true),
    ], october);

    expect([for (final r in rows) (r.group.id, r.totalMinor, r.share)], [('food', 3000, 0.75), ('rent', 1000, 0.25)]);
  });

  test('ties sort by name, whatever order the entries came in', () {
    final rows = run([
      entry('rent', 1000, DateTime.utc(2026, 10, 2)),
      entry('gym', 1000, DateTime.utc(2026, 10, 3)),
      entry('books', 1000, DateTime.utc(2026, 10, 4)),
    ], october);

    expect([for (final r in rows) r.group.name], ['Books', 'Gym', 'Rent']);
  });

  test('December and January stay apart across the year boundary', () {
    final entries = [
      entry('food', 1000, DateTime.utc(2025, 12, 31)),
      entry('rent', 2000, DateTime.utc(2026, 1, 1)),
      entry('gym', 4000, DateTime.utc(2026, 12, 15)), // the next December
    ];

    expect([for (final r in run(entries, const CalendarMonth(2025, 12))) (r.group.id, r.totalMinor)], [('food', 1000)]);
    expect([for (final r in run(entries, const CalendarMonth(2026, 1))) (r.group.id, r.totalMinor)], [('rent', 2000)]);
  });

  test('shares of an uneven month add up to 1', () {
    final rows = run([
      entry('food', 1000, DateTime.utc(2026, 10, 2)),
      entry('rent', 1000, DateTime.utc(2026, 10, 3)),
      entry('gym', 1000, DateTime.utc(2026, 10, 4)),
    ], october);

    expect(rows.fold<double>(0, (sum, r) => sum + r.share), closeTo(1, 1e-9));
    expect(rows.first.share, closeTo(1 / 3, 1e-9));
  });

  test('a month with no entries has no rows', () {
    expect(run([entry('food', 1000, DateTime.utc(2026, 9, 2))], october), isEmpty);
  });
}
