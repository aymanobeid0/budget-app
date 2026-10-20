import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/money.dart';
import '../../../core/month/breakdown.dart';
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
import '../../categories/category.dart';
import '../../categories/cubit/category_cubit.dart';
import '../../categories/cubit/category_state.dart';
import '../../income/cubit/income_cubit.dart';
import '../../income/cubit/income_state.dart';
import '../../income/income.dart';
import '../../settings/cubit/currency_cubit.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../expense.dart';
import 'expense_form_sheet.dart';
import 'expenses_screen.dart';

/// Expenses tab, laid out like the Income tab: one month at a time. The
/// month header and total card (swipe either to change month) over that
/// month's Expenses, newest first and grouped by day. Tapping the total card
/// breaks the month down by Category; picking one filters the list to it.
class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  /// The Category the list is filtered to. Kept when the month changes.
  String? _categoryFilter;

  Future<void> _openBreakdown(
      {required String label, required List<Expense> expenses, required Map<String, Category> byId}) async {
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
    if (picked != null && mounted) setState(() => _categoryFilter = picked);
  }

  Future<bool> _confirmDelete(BuildContext context, Expense expense) async {
    final result = await confirmDeleteExpense(context, expense);
    if (result && context.mounted) context.read<ExpenseCubit>().deleteExpense(expense.id);
    return false; // the list reloads from the cubit
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final router = GoRouter.maybeOf(context);
    final chosen = context.watch<ChosenMonthCubit>();
    final month = chosen.state;
    final currency = context.watch<CurrencyCubit>().state;
    final income = _watchIncome(context);
    final header = ScreenHeader(
      title: 'Expenses',
      leading: SquareIconButton(
        key: const Key('add-expense-btn'),
        icon: Icons.add_rounded,
        tooltip: 'Add expense',
        onTap: () => showExpenseSheet(context),
      ),
      trailing: SquareIconButton(
        key: const Key('expense-categories-btn'),
        icon: Icons.grid_view_rounded,
        tooltip: 'Categories',
        onTap: router == null ? null : () => router.push('/categories'),
      ),
    );

    return Scaffold(
      key: const Key('expense-list-screen'),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, catState) {
            // Deleted Categories too, so past Expenses keep their name.
            final catMap = catState is CategoryLoaded ? catState.categoryById : const <String, Category>{};

            return BlocBuilder<ExpenseCubit, ExpenseState>(
              builder: (context, state) {
                if (state is ExpenseError) {
                  return Column(children: [
                    header,
                    Expanded(
                      child: Center(child: Text('Error: ${state.message}', style: TextStyle(color: scheme.error))),
                    ),
                  ]);
                }
                if (state is! ExpenseLoaded) {
                  return Column(children: [header, const Expanded(child: Center(child: CircularProgressIndicator()))]);
                }

                final earliest = earliestMonth([
                  for (final e in state.expenses) if (e.deletedAt == null) e.spentOn,
                  for (final i in income) if (i.deletedAt == null) i.paidOn,
                ]);
                final inMonth = [for (final e in state.expenses) if (month.contains(e.spentOn)) e];
                final filter = _categoryFilter;
                final shown = filter == null ? inMonth : [for (final e in inMonth) if (e.categoryId == filter) e];
                final days = <String, List<Expense>>{};
                for (final e in shown) {
                  days.putIfAbsent(e.spentOnIso, () => []).add(e);
                }
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
                          // With no Expenses at all, the welcome below says it all.
                          if (state.expenses.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            // Tapping the card breaks the month down by Category.
                            GestureDetector(
                              onTap: () => _openBreakdown(label: label, expenses: inMonth, byId: catMap),
                              child: _TotalCard(
                                label: label,
                                totalMinor: inMonth.fold(0, (sum, e) => sum + e.amountMinor),
                              ),
                            ),
                          ],
                        ]),
                      ),
                    ),
                    if (filter != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 16, AppSpace.gutter, 0),
                        child: GroupFilterChip(
                          group: categoryGroup(filter, catMap[filter]),
                          onClear: () => setState(() => _categoryFilter = null),
                        ),
                      ),
                    // Kept while the list is empty, so the first Expense animates in too.
                    // Keyed by month and filter, so a new month's rows show at once.
                    AnimatedEntries(key: ValueKey((month, filter)), children: [
                      for (final day in days.entries) ...[
                        DayHeader(
                          key: ValueKey('expense-day-${day.key}'),
                          day: day.value.first.spentOn,
                          today: chosen.today,
                          totalMinor: day.value.fold(0, (sum, e) => sum + e.amountMinor),
                          currency: currency,
                        ),
                        for (final e in day.value)
                          ExpenseRow(
                            key: ValueKey('expense-list-row-${e.id}'),
                            expense: e,
                            category: catMap[e.categoryId],
                            onTap: () => showExpenseSheet(context, expense: e),
                            onDelete: () => _confirmDelete(context, e),
                          ),
                      ],
                    ]),
                    // After the list, so a deleted last Expense leaves above it.
                    if (state.expenses.isEmpty)
                      _EmptyExpenses(onAdd: () => showExpenseSheet(context))
                    else if (days.isEmpty)
                      emptyMonthState(
                        entries: 'Expenses',
                        monthLabel: label,
                        isCurrent: chosen.isCurrent,
                        filteredTo: filter == null ? null : categoryGroup(filter, catMap[filter]).name,
                        filteredMessage: 'Nothing in this Category this month.',
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

/// The Income list, for the month swipe's earliest month; empty when the app
/// runs without the income feature (tests).
List<Income> _watchIncome(BuildContext context) {
  if (maybeIncomeCubit(context) == null) return const [];
  final state = context.watch<IncomeCubit>().state;
  return state is IncomeLoaded ? state.income : const [];
}

/// The chosen month's Expense total.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.label, required this.totalMinor});

  /// The chosen month's name, as the header shows it.
  final String label;
  final int totalMinor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('expense-total'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: raisedDecoration(context, radius: AppRadius.xl, shadow: AppShadows.panel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spent in $label',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money.withLabel(totalMinor, context.watch<CurrencyCubit>().state),
              style: AppType.heroAmount.copyWith(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_rounded,
      title: 'No Expenses yet',
      message: 'Log what you spend and see where your money goes, day by day.',
      action: FilledButton.icon(
        key: const Key('add-first-expense-in-list'),
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log your first Expense'),
      ),
    );
  }
}
