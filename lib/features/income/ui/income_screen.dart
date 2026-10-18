import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/money.dart';
import '../../../core/month/breakdown_sheet.dart';
import '../../../core/month/chosen_month_cubit.dart';
import '../../../core/month/earliest_month.dart';
import '../../../core/month/empty_month.dart';
import '../../../core/month/month_header.dart';
import '../../../core/theme/animated_entries.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/empty_state.dart';
import '../../../core/theme/widgets.dart';
import '../../categories/ui/category_icon_helper.dart';
import '../../expenses/cubit/expense_cubit.dart';
import '../../expenses/cubit/expense_state.dart';
import '../../expenses/expense.dart';
import '../../expenses/ui/expense_form_sheet.dart';
import '../../settings/cubit/currency_cubit.dart';
import '../cubit/income_cubit.dart';
import '../cubit/income_state.dart';
import '../income.dart';
import '../income_breakdown.dart';
import '../income_source.dart';

const _shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Income tab: one month at a time. The month header and total card (swipe
/// either to change month) over that month's Income, newest first and
/// grouped by day. Tapping the total card breaks the month down by Income
/// Source; picking one filters the list to it.
class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  /// The Income Source the list is filtered to. Kept when the month changes.
  String? _sourceFilter;

  Future<void> _openBreakdown({required String label, required IncomeLoaded inMonth}) async {
    final rows = incomeSourceBreakdown(
      inMonth.income,
      month: context.read<ChosenMonthCubit>().state,
      sourceById: inMonth.sourceById,
    );
    final picked = await showBreakdownSheet(
      context,
      title: 'Income in $label',
      totalMinor: inMonth.totalMinor,
      rows: rows,
      currency: context.read<CurrencyCubit>().state,
    );
    if (picked != null && mounted) setState(() => _sourceFilter = picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final router = GoRouter.maybeOf(context);
    final chosen = context.watch<ChosenMonthCubit>();
    final month = chosen.state;
    final expenses = _watchExpenses(context);
    final header = ScreenHeader(
      title: 'Income',
      trailing: SquareIconButton(
        key: const Key('income-sources-btn'),
        icon: Icons.tune_rounded,
        tooltip: 'Income Sources',
        onTap: router == null ? null : () => router.go('/settings/income-sources'),
      ),
    );

    return Scaffold(
      key: const Key('income-screen'),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<IncomeCubit, IncomeState>(
          builder: (context, state) {
            if (state is IncomeError) {
              return Column(
                children: [
                  header,
                  Expanded(
                    child: Center(
                      child: Text('Error: ${state.message}', style: TextStyle(color: scheme.error)),
                    ),
                  ),
                ],
              );
            }
            if (state is! IncomeLoaded) {
              return Column(
                children: [
                  header,
                  const Expanded(child: Center(child: CircularProgressIndicator())),
                ],
              );
            }

            final earliest = earliestMonth([
              for (final e in expenses) if (e.deletedAt == null) e.spentOn,
              for (final i in state.income) if (i.deletedAt == null) i.paidOn,
            ]);
            final inMonth = state.forMonth(month);
            final sources = inMonth.sourceById;
            final filter = _sourceFilter;
            final shown = filter == null ? inMonth : state.forMonth(month, sourceId: filter);
            final days = shown.groupedByDay;
            final dayTotals = shown.dayTotals;
            final label = month.label(today: chosen.today);
            return ListView(
              padding: const EdgeInsets.only(bottom: 130),
              children: [
                header,
                MonthSwipeArea(
                  earliest: earliest,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 14, AppSpace.gutter, 0),
                    child: Column(children: [
                      MonthHeader(earliest: earliest),
                      // With no Income at all, the welcome below says it all.
                      if (state.income.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        // Tapping the card breaks the month down by Income Source.
                        GestureDetector(
                          onTap: () => _openBreakdown(label: label, inMonth: inMonth),
                          child: _TotalCard(label: label, totalMinor: inMonth.totalMinor),
                        ),
                      ],
                    ]),
                  ),
                ),
                if (filter != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 16, AppSpace.gutter, 0),
                    child: GroupFilterChip(
                      group: incomeSourceGroup(filter, sources[filter]),
                      onClear: () => setState(() => _sourceFilter = null),
                    ),
                  ),
                // Kept while the list is empty, so the first Income animates in too.
                // Keyed by month and filter, so a new month's rows show at once.
                AnimatedEntries(key: ValueKey((month, filter)), children: [
                  for (final day in days.entries) ...[
                    _DayHeader(
                      key: ValueKey('income-day-${day.key}'),
                      day: day.value.first.paidOn,
                      today: chosen.today,
                      totalMinor: dayTotals[day.key]!,
                    ),
                    for (final i in day.value)
                      _IncomeRow(
                        key: ValueKey('income-row-${i.id}'),
                        income: i,
                        source: sources[i.sourceId],
                        onTap: () => showExpenseSheet(context, income: i),
                      ),
                  ],
                ]),
                // After the list, so a deleted last Income leaves above it.
                if (state.income.isEmpty)
                  _EmptyIncome(onAdd: () => showExpenseSheet(context, kind: EntryKind.income))
                else if (days.isEmpty)
                  emptyMonthState(
                    entries: 'Income',
                    monthLabel: label,
                    isCurrent: chosen.isCurrent,
                    filteredTo: filter == null ? null : incomeSourceGroup(filter, sources[filter]).name,
                    filteredMessage: 'Nothing from this Income Source this month.',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The Expense list, rebuilding [context] as it changes; empty when the app
/// runs without the expenses feature (tests).
List<Expense> _watchExpenses(BuildContext context) {
  if (maybeExpenseCubit(context) == null) return const [];
  final state = context.watch<ExpenseCubit>().state;
  return state is ExpenseLoaded ? state.expenses : const [];
}

/// The chosen month's Income total.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.label, required this.totalMinor});

  /// The chosen month's name, as the header shows it.
  final String label;
  final int totalMinor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('income-total'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: raisedDecoration(context, radius: AppRadius.xl, shadow: AppShadows.panel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Income in $label',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(Money.withLabel(totalMinor, context.watch<CurrencyCubit>().state), style: AppType.heroAmount.copyWith(color: AppColors.income)),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({super.key, required this.day, required this.today, required this.totalMinor});
  final DateTime day;

  /// Now, by the chosen month's clock, for "Today" and "Yesterday".
  final DateTime today;
  final int totalMinor;

  String _label() {
    final now = this.today;
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final label = '${_weekdays[d.weekday - 1]}, ${d.day} ${_shortMonths[d.month - 1]}';
    return d.year == now.year ? label : '$label ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 22, AppSpace.gutter, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(_label(), style: AppType.caption.copyWith(color: scheme.onSurfaceVariant)),
          ),
          Text(
            Money.withLabel(totalMinor, context.watch<CurrencyCubit>().state),
            style: AppType.caption.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppFonts.tabular),
          ),
        ],
      ),
    );
  }
}

class _IncomeRow extends StatelessWidget {
  const _IncomeRow({super.key, required this.income, required this.source, required this.onTap});

  final Income income;
  final IncomeSource? source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = source != null ? Color(source!.color) : AppColors.income;
    final icon = source != null ? CategoryIconHelper.getIcon(source!.icon) : Icons.payments_rounded;

    return InkWell(
      key: ValueKey('income-${income.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: 10),
        child: Row(
          children: [
            CategoryIconTile(icon: icon, color: color, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Text(source?.name ?? 'Unknown source', style: AppType.rowTitle.copyWith(color: scheme.onSurface)),
            ),
            Text('+${Money.format(income.amountMinor)}', style: AppType.rowAmount.copyWith(color: AppColors.income)),
          ],
        ),
      ),
    );
  }
}

class _EmptyIncome extends StatelessWidget {
  const _EmptyIncome({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.payments_rounded,
      title: 'No Income yet',
      message: 'Log money you were paid and see what comes in next to what you spend.',
      action: FilledButton.icon(
        key: const Key('add-first-income'),
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log your first Income'),
      ),
    );
  }
}
