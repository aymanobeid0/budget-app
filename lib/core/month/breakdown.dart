import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'calendar_month.dart';

/// What a month's entries are grouped by in a breakdown: a Category for
/// Expenses, an Income Source for Income.
class BreakdownGroup extends Equatable {
  const BreakdownGroup({required this.id, required this.name, required this.icon, required this.color});

  final String id;
  final String name;
  final IconData icon;
  final Color color;

  @override
  List<Object?> get props => [id, name, icon, color];
}

/// One group's total for the month and its share of the month's total.
class BreakdownRow extends Equatable {
  const BreakdownRow({required this.group, required this.totalMinor, required this.share});

  final BreakdownGroup group;
  final int totalMinor;

  /// From 0 to 1; a month's shares add up to 1.
  final double share;

  @override
  List<Object?> get props => [group, totalMinor, share];
}

/// The [month]'s total per group, largest first and ties by name. Deleted
/// entries don't count. [describe] gives a group's name, icon and colour by
/// id, and must resolve deleted groups too, so the rows add up to the
/// month's total.
List<BreakdownRow> monthBreakdown<T>(
  Iterable<T> entries, {
  required CalendarMonth month,
  required DateTime Function(T) dateOf,
  required String Function(T) groupOf,
  required int Function(T) amountOf,
  required bool Function(T) isDeleted,
  required BreakdownGroup Function(String groupId) describe,
}) {
  final totals = <String, int>{};
  var monthTotal = 0;
  for (final e in entries) {
    if (isDeleted(e) || !month.contains(dateOf(e))) continue;
    totals.update(groupOf(e), (t) => t + amountOf(e), ifAbsent: () => amountOf(e));
    monthTotal += amountOf(e);
  }

  final rows = [
    for (final MapEntry(key: id, value: total) in totals.entries)
      BreakdownRow(group: describe(id), totalMinor: total, share: monthTotal == 0 ? 0 : total / monthTotal),
  ];
  rows.sort((a, b) {
    final byTotal = b.totalMinor.compareTo(a.totalMinor);
    return byTotal != 0 ? byTotal : a.group.name.toLowerCase().compareTo(b.group.name.toLowerCase());
  });
  return rows;
}
