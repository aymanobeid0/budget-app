import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/money.dart';
import '../../../core/month/breakdown.dart';
import '../../../core/month/breakdown_sheet.dart';
import '../../../core/month/chosen_month_cubit.dart';
import '../../../core/month/day_header.dart';
import '../../../core/month/earliest_month.dart';
import '../../../core/month/month_header.dart';
import '../../../core/sync/sync_status_view.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/empty_state.dart';
import '../../../core/theme/widgets.dart';
import '../../categories/category.dart';
import '../../categories/cubit/category_cubit.dart';
import '../../categories/cubit/category_state.dart';
import '../../categories/ui/category_icon_helper.dart';
import '../../income/cubit/income_cubit.dart';
import '../../income/cubit/income_state.dart';
import '../../income/income.dart';
import '../../income/ui/net_card.dart';
import '../../settings/cubit/currency_cubit.dart';
import '../cubit/expense_cubit.dart';
import 'expense_form_sheet.dart';
import '../cubit/expense_state.dart';
import '../expense.dart';
import '../month_spending.dart';


/// Home, Monex's Overview: the chosen month at a glance. The month header and
/// gradient "spent" card (swipe either to change month) over that month's
/// Net, then the latest Expenses. Tapping the card breaks the month down by
/// Category; picking one opens the Expenses tab filtered to it.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  Future<void> _openBreakdown(BuildContext context,
      {required String label, required List<Expense> expenses, required Map<String, Category> byId}) async {
    final router = GoRouter.maybeOf(context);
    final rows = monthBreakdown<Expense>(
      expenses,
      month: context.read<ChosenMonthCubit>().state,
      dateOf: (e) => e.spentOn,
      groupOf: (e) => e.categoryId,
      amountOf: (e) => e.amountMinor,
      isDeleted: (e) => e.deletedAt != null,
      describe: (id) => categoryGroup(id, byId[id]),
    );
    final picked = await showBreakdownSheet(
      context,
      title: 'Spent in $label',
      totalMinor: rows.fold(0, (sum, r) => sum + r.totalMinor),
      rows: rows,
      currency: context.read<CurrencyCubit>().state,
    );
    if (picked != null) router?.go(expensesFilteredTo(picked));
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    // Net needs Income; Home without the income feature (tests) skips it.
    final hasIncome = maybeIncomeCubit(context) != null;
    final chosen = context.watch<ChosenMonthCubit>();
    final month = chosen.state;
    final income = _watchIncome(context);

    return Scaffold(
      key: const Key('expenses-screen'),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, catState) {
            // Deleted Categories too, so past Expenses keep their name.
            final catMap = catState is CategoryLoaded ? catState.categoryById : const <String, Category>{};

            return BlocBuilder<ExpenseCubit, ExpenseState>(
              builder: (context, state) {
                final header = ScreenHeader(
                  title: 'Home',
                  leading: AddEntryButton(
                    key: const Key('add-expense-btn'),
                    label: 'Add Expense',
                    tooltip: 'Add expense',
                    onPressed: () => showExpenseSheet(context),
                  ),
                );

                if (state is ExpenseLoading || state is ExpenseInitial) {
                  return Column(children: [header, const Expanded(child: Center(child: CircularProgressIndicator()))]);
                }
                if (state is ExpenseError) {
                  return Column(children: [
                    header,
                    Expanded(
                      child: Center(child: LoadErrorState(what: 'your Expenses', onRetry: () => context.read<ExpenseCubit>().load())),
                    ),
                  ]);
                }
                if (state is! ExpenseLoaded) return const SizedBox.shrink();

                final earliest = earliestMonth([
                  for (final e in state.expenses) if (e.deletedAt == null) e.spentOn,
                  for (final i in income) if (i.deletedAt == null) i.paidOn,
                ]);
                final monthExpenses = [for (final e in state.expenses) if (month.contains(e.spentOn)) e];
                final label = month.label(today: chosen.today);
                return ListView(
                  padding: const EdgeInsets.only(bottom: 130),
                  children: [
                    header,
                    SyncAttentionIndicator(onTap: router == null ? null : () => router.go('/settings')),
                    MonthSwipeArea(
                      earliest: earliest,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 14, AppSpace.gutter, 0),
                        child: Column(children: [
                          MonthHeader(earliest: earliest),
                          const SizedBox(height: 8),
                          // Tapping the card breaks the month down by Category.
                          GestureDetector(
                            onTap: () => _openBreakdown(context, label: label, expenses: monthExpenses, byId: catMap),
                            child: _SpentCard(
                              label: label,
                              expenses: monthExpenses,
                              allExpenses: state.expenses,
                              today: chosen.isCurrent ? chosen.today : null,
                              comparison: compareWithPreviousMonth(
                                summarizeMonthSpending(expenses: state.expenses, month: month),
                                currency: context.watch<CurrencyCubit>().state,
                                today: chosen.today,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    if (hasIncome)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(AppSpace.gutter, 16, AppSpace.gutter, 0),
                        child: NetCard(),
                      ),
                    if (state.expenses.isEmpty)
                      const _EmptyHome()
                    else
                      _LatestEntries(
                        expenses: state.expenses,
                        byId: catMap,
                        onSeeAll: router == null ? null : () => router.go('/expenses'),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The Expenses tab's location, filtered to [categoryId].
String expensesFilteredTo(String categoryId) =>
    Uri(path: '/expenses', queryParameters: {'category': categoryId}).toString();

/// A Category as a breakdown group; Expenses whose Category is gone
/// entirely show as Uncategorized, as their rows do.
BreakdownGroup categoryGroup(String id, Category? category) => BreakdownGroup(
      id: id,
      name: category?.name ?? 'Uncategorized',
      icon: category != null ? CategoryIconHelper.getIcon(category.icon) : Icons.receipt_long_rounded,
      color: category != null ? Color(category.color) : AppColors.primary,
    );

/// The Income list, rebuilding [context] as it changes; empty when the app
/// runs without the income feature (tests).
List<Income> _watchIncome(BuildContext context) {
  if (maybeIncomeCubit(context) == null) return const [];
  final state = context.watch<IncomeCubit>().state;
  return state is IncomeLoaded ? state.income : const [];
}

/// Shared delete confirmation (list swipe and the edit screen).
Future<bool> confirmDeleteExpense(BuildContext context, Expense expense) =>
    confirmDeleteEntry(context,
        noun: 'expense', amountMinor: expense.amountMinor, currency: context.read<CurrencyCubit>().state);

/// Delete confirmation for an Expense or an Income.
Future<bool> confirmDeleteEntry(BuildContext context,
    {required String noun, required int amountMinor, required Currency currency}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete $noun?', style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text('This removes the ${Money.withLabel(amountMinor, currency)} $noun.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.expense,
            minimumSize: const Size(88, 44),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result == true;
}

/// The chosen month's spending. Today and this week show only when [today]
/// is given, on the current month.
class _SpentCard extends StatelessWidget {
  const _SpentCard(
      {required this.label, required this.expenses, required this.allExpenses, required this.today, this.comparison});
  final String label;

  /// How the month compares with the month before; hidden when null.
  final String? comparison;

  /// The chosen month's Expenses.
  final List<Expense> expenses;

  /// Every Expense, for today and this week: a week can start in the month
  /// before.
  final List<Expense> allExpenses;
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final now = today;
    final day = now == null ? null : DateTime(now.year, now.month, now.day);
    final weekStart = day?.subtract(Duration(days: day.weekday - 1));

    final month = expenses.fold(0, (sum, e) => sum + e.amountMinor);
    var todayTotal = 0, week = 0;
    if (day != null) {
      for (final e in allExpenses) {
        final d = DateTime(e.spentOn.year, e.spentOn.month, e.spentOn.day);
        if (d == day) todayTotal += e.amountMinor;
        if (!d.isBefore(weekStart!) && !d.isAfter(day)) week += e.amountMinor;
      }
    }

    return Container(
      key: const Key('month-summary-card'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: gradientDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spent in $label',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onPrimaryMuted),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              key: const Key('month-total'),
              TextSpan(children: [
                TextSpan(text: Money.format(month)),
                TextSpan(
                  text: '  ${context.watch<CurrencyCubit>().state.code}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onPrimaryMuted),
                ),
              ]),
              style: AppType.heroAmount,
            ),
          ),
          if (comparison != null) ...[
            const SizedBox(height: 6),
            Text(
              comparison!,
              key: const Key('month-comparison'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onPrimaryMuted),
            ),
          ],
          if (day != null) ...[
            const SizedBox(height: 18),
            // Side by side at the usual text sizes; stacked at large ones, so
            // neither amount is cut off.
            if (MediaQuery.textScalerOf(context).scale(10) > 12)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Stat(icon: Icons.today_rounded, label: 'Today', minor: todayTotal),
                  const SizedBox(height: 12),
                  _Stat(icon: Icons.bar_chart_rounded, label: 'This week', minor: week),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _Stat(icon: Icons.today_rounded, label: 'Today', minor: todayTotal)),
                  const SizedBox(width: 12),
                  Expanded(child: _Stat(icon: Icons.bar_chart_rounded, label: 'This week', minor: week)),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.minor});
  final IconData icon;
  final String label;
  final int minor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.onPrimaryMuted)),
              Text(
                Money.withLabel(minor, context.watch<CurrencyCubit>().state),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFeatures: AppFonts.tabular,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Monex's "Latest Entries": the five most recent Expenses, newest first,
/// with a "more" button that opens the Expenses tab.
class _LatestEntries extends StatelessWidget {
  const _LatestEntries({required this.expenses, required this.byId, required this.onSeeAll});
  final List<Expense> expenses;
  final Map<String, Category> byId;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final latest = [for (final e in expenses) if (e.deletedAt == null) e]
      ..sort((a, b) => b.spentOn.compareTo(a.spentOn));
    return Column(
      key: const Key('latest-entries'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 28, AppSpace.gutter, 8),
          child: Row(
            children: [
              Expanded(child: Text('Latest Entries', style: AppType.section.copyWith(color: scheme.onSurface))),
              SquareIconButton(icon: Icons.more_horiz_rounded, tooltip: 'All Expenses', onTap: onSeeAll),
            ],
          ),
        ),
        for (final e in latest.take(5))
          ExpenseRow(
            key: ValueKey('home-row-${e.id}'),
            expense: e,
            category: byId[e.categoryId],
            onTap: () => showExpenseSheet(context, expense: e),
            onDelete: () => confirmDeleteExpense(context, e),
          ),
      ],
    );
  }
}

/// First launch: the Add Expense button below is the way in.
class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.receipt_long_rounded,
      title: 'No Expenses yet',
      message: 'Tap Add Expense to log what you spend, and your month takes shape here.',
    );
  }
}

/// One Expense in a day of the Expenses list: its Category and amount (the
/// day header above names the day); tap to edit, swipe to delete.
class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    super.key,
    required this.expense,
    required this.category,
    required this.onTap,
    required this.onDelete,
  });

  final Expense expense;
  final Category? category;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = category != null ? Color(category!.color) : AppColors.primary;
    final icon = category != null ? CategoryIconHelper.getIcon(category!.icon) : Icons.receipt_long_rounded;

    return Dismissible(
      key: ValueKey('expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpace.gutter),
        color: AppColors.expense.withValues(alpha: 0.08),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: 10),
          child: Row(
            children: [
              CategoryIconTile(icon: icon, color: color, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category?.name ?? 'Uncategorized', style: AppType.rowTitle.copyWith(color: scheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(shortDate(expense.spentOn), style: AppType.caption.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Text('- ${Money.format(expense.amountMinor)}', style: AppType.rowAmount.copyWith(color: scheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}
