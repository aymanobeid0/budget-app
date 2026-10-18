import 'package:flutter/material.dart';

import '../../core/month/breakdown.dart';
import '../../core/month/calendar_month.dart';
import '../../core/theme/app_theme.dart';
import '../categories/ui/category_icon_helper.dart';
import 'income.dart';
import 'income_source.dart';

/// The [month]'s Income per Income Source, largest first. [sourceById] must
/// include deleted Income Sources, so their past Income keeps its name.
List<BreakdownRow> incomeSourceBreakdown(
  Iterable<Income> income, {
  required CalendarMonth month,
  required Map<String, IncomeSource> sourceById,
}) =>
    monthBreakdown<Income>(
      income,
      month: month,
      dateOf: (i) => i.paidOn,
      groupOf: (i) => i.sourceId,
      amountOf: (i) => i.amountMinor,
      isDeleted: (i) => i.deletedAt != null,
      describe: (id) => incomeSourceGroup(id, sourceById[id]),
    );

/// An Income Source as a breakdown group; Income whose source is gone
/// entirely shows as Unknown source, as its rows do.
BreakdownGroup incomeSourceGroup(String id, IncomeSource? source) => BreakdownGroup(
      id: id,
      name: source?.name ?? 'Unknown source',
      icon: source != null ? CategoryIconHelper.getIcon(source.icon) : Icons.payments_rounded,
      color: source != null ? Color(source.color) : AppColors.income,
    );
