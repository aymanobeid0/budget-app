import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/money.dart';
import '../../../core/month/breakdown_sheet.dart';
import '../../../core/month/chosen_month_cubit.dart';
import '../../../core/month/day_header.dart';
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
import '../../expenses/ui/expenses_screen.dart' show confirmDeleteEntry;
import '../../settings/cubit/currency_cubit.dart';
import '../cubit/income_cubit.dart';
import '../cubit/income_state.dart';
import '../income.dart';
import '../income_breakdown.dart';
import '../income_source.dart';

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

  Future<bool> _confirmDelete(BuildContext context, Income income) async {
    final yes = await confirmDeleteEntry(context,
        noun: 'income', amountMinor: income.amountMinor, currency: context.read<CurrencyCubit>().state);
    if (yes && context.mounted) context.read<IncomeCubit>().deleteIncome(income.id);
    return false; // the list reloads from the cubit
  }

  @override
  Widget build(BuildContext context) {
    final chosen = context.watch<ChosenMonthCubit>();
    final month = chosen.state;
    final expenses = _watchExpenses(context);
    final header = ScreenHeader(
      title: 'Income',
      leading: AddEntryButton(
        key: const Key('add-income-btn'),
        label: 'Add Income',
        tooltip: 'Add income',
        onPressed: () => showExpenseSheet(context, kind: EntryKind.income),
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
                      child: LoadErrorState(what: 'your Income', onRetry: () => context.read<IncomeCubit>().load()),
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
                    DayHeader(
                      key: ValueKey('income-day-${day.key}'),
                      day: day.value.first.paidOn,
                      today: chosen.today,
                      totalMinor: dayTotals[day.key]!,
                      currency: context.watch<CurrencyCubit>().state,
                    ),
                    for (final i in day.value)
                      _IncomeRow(
                        key: ValueKey('income-row-${i.id}'),
                        income: i,
                        source: sources[i.sourceId],
                        onTap: () => showExpenseSheet(context, income: i),
                        onDelete: () => _confirmDelete(context, i),
                      ),
                  ],
                ]),
                // After the list, so a deleted last Income leaves above it.
                if (state.income.isEmpty)
                  const _EmptyIncome()
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
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: panelDecoration(context),
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

class _IncomeRow extends StatelessWidget {
  const _IncomeRow(
      {super.key, required this.income, required this.source, required this.onTap, required this.onDelete});

  final Income income;
  final IncomeSource? source;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = source != null ? Color(source!.color) : AppColors.income;
    final icon = source != null ? CategoryIconHelper.getIcon(source!.icon) : Icons.payments_rounded;

    return Dismissible(
      key: ValueKey('income-swipe-${income.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpace.gutter),
        color: AppColors.expense.withValues(alpha: 0.08),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
      ),
      child: InkWell(
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
      ),
    );
  }
}

class _EmptyIncome extends StatelessWidget {
  const _EmptyIncome();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.payments_rounded,
      title: 'No Income yet',
      message: 'Tap Add Income to log money you were paid and see it next to what you spend.',
    );
  }
}
