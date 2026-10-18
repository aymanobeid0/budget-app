import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/money.dart';
import '../../../core/month/breakdown.dart';
import '../../../core/month/breakdown_sheet.dart';
import '../../../core/month/chosen_month_cubit.dart';
import '../../../core/month/month_header.dart';
import '../../../core/sync/sync_status_view.dart';
import '../../../core/theme/animated_entries.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/empty_state.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../../../core/theme/widgets.dart';
import '../../categories/category.dart';
import '../../categories/cubit/category_cubit.dart';
import '../../categories/cubit/category_state.dart';
import '../../categories/ui/category_icon_helper.dart';
import '../../income/cubit/income_cubit.dart';
import '../../income/cubit/income_state.dart';
import '../../income/earliest_month.dart';
import '../../income/income.dart';
import '../../income/ui/net_card.dart';
import '../../settings/cubit/currency_cubit.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../expense.dart';
import 'expense_form_sheet.dart';

const _shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Home: one month at a time. The month header and blue "spent" card (swipe
/// either to change month) over that month's Expenses. Tapping the card
/// breaks the month down by Category; picking one filters the list to it.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
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
      describe: (id) => _categoryGroup(id, byId[id]),
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
            final categories = catState is CategoryLoaded ? catState.categories : <Category>[];
            // Deleted Categories too, so past Expenses keep their name.
            final catMap = {
              for (final c in categories) c.id: c,
              if (catState is CategoryLoaded) ...catState.categoryById,
            };

            return BlocBuilder<ExpenseCubit, ExpenseState>(
              builder: (context, state) {
                final header = ScreenHeader(
                  title: 'Home',
                  leading: SquareIconButton(
                    icon: Icons.grid_view_rounded,
                    tooltip: 'Categories',
                    onTap: router == null ? null : () => router.go('/settings/categories'),
                  ),
                  trailing: const ThemeToggleButton(),
                );

                if (state is ExpenseLoading || state is ExpenseInitial) {
                  return Column(children: [header, const Expanded(child: Center(child: CircularProgressIndicator()))]);
                }
                if (state is ExpenseError) {
                  return Column(children: [
                    header,
                    Expanded(
                      child: Center(child: Text('Error: ${state.message}', style: TextStyle(color: scheme.error))),
                    ),
                  ]);
                }
                if (state is! ExpenseLoaded) return const SizedBox.shrink();

                final earliest = earliestEntryMonth(expenses: state.expenses, income: income);
                final monthExpenses = [for (final e in state.expenses) if (month.contains(e.spentOn)) e];
                final filter = _categoryFilter;
                final expenses = filter == null
                    ? monthExpenses
                    : [for (final e in monthExpenses) if (e.categoryId == filter) e];
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
                            onTap: () => _openBreakdown(label: label, expenses: monthExpenses, byId: catMap),
                            child: _SpentCard(
                              label: label,
                              expenses: monthExpenses,
                              today: chosen.isCurrent ? chosen.today : null,
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 26, AppSpace.gutter, 6),
                      child: Text('Transactions', style: AppType.title.copyWith(color: scheme.onSurface)),
                    ),
                    if (filter != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, 4),
                        child: GroupFilterChip(
                          group: _categoryGroup(filter, catMap[filter]),
                          onClear: () => setState(() => _categoryFilter = null),
                        ),
                      ),
                    // Kept while the list is empty, so the first Expense animates in too.
                    // Keyed by month and filter, so a new month's rows show at once.
                    AnimatedEntries(key: ValueKey((month, filter)), children: [
                      for (final e in expenses)
                        _TransactionRow(
                          key: ValueKey('expense-row-${e.id}'),
                          expense: e,
                          category: catMap[e.categoryId],
                          onTap: () => showExpenseSheet(context, expense: e),
                          onDelete: () => _confirmDelete(context, e),
                        ),
                    ]),
                    if (state.expenses.isEmpty)
                      _EmptyTransactions(onAdd: () => showExpenseSheet(context))
                    else if (expenses.isEmpty)
                      EmptyState(
                        icon: Icons.event_busy_rounded,
                        title: filter == null
                            ? 'No Expenses in $label'
                            : 'No ${_categoryGroup(filter, catMap[filter]).name} Expenses in $label',
                        message: filter != null
                            ? 'Nothing in this Category this month.'
                            : chosen.isCurrent
                                ? 'Nothing logged this month yet.'
                                : 'Nothing was logged this month.',
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

/// A Category as a breakdown group; Expenses whose Category is gone
/// entirely show as Uncategorized, as their rows do.
BreakdownGroup _categoryGroup(String id, Category? category) => BreakdownGroup(
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
  const _SpentCard({required this.label, required this.expenses, required this.today});
  final String label;

  /// The chosen month's Expenses.
  final List<Expense> expenses;
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = isDarkOf(context);
    final now = today;
    final day = now == null ? null : DateTime(now.year, now.month, now.day);
    final weekStart = day?.subtract(Duration(days: day.weekday - 1));

    var month = 0, todayTotal = 0, week = 0;
    for (final e in expenses) {
      final d = DateTime(e.spentOn.year, e.spentOn.month, e.spentOn.day);
      month += e.amountMinor;
      if (d == day) todayTotal += e.amountMinor;
      if (day != null && !d.isBefore(weekStart!) && !d.isAfter(day)) week += e.amountMinor;
    }

    return Container(
      key: const Key('month-summary-card'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: isDark ? null : AppShadows.heroCard,
      ),
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
          if (day != null) ...[
            const SizedBox(height: 18),
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

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_rounded,
      title: 'No Expenses yet',
      message: 'Log what you spend and your month takes shape here.',
      action: FilledButton.icon(
        key: const Key('add-first-expense'),
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add your first Expense'),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
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

  String _subtitle() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(expense.spentOn.year, expense.spentOn.month, expense.spentOn.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) {
      final t = expense.createdAt.toLocal();
      final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
      return '${h.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
    }
    if (diff == 1) return 'Yesterday';
    final label = '${_weekdays[d.weekday - 1]}, ${d.day} ${_shortMonths[d.month - 1]}';
    return d.year == now.year ? label : '$label ${d.year}';
  }

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
              CategoryIconTile(icon: icon, color: color, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category?.name ?? 'Uncategorized', style: AppType.rowTitle.copyWith(color: scheme.onSurface)),
                    const SizedBox(height: 3),
                    Text(_subtitle(), style: AppType.caption.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Text('−${Money.format(expense.amountMinor)}', style: AppType.rowAmount),
            ],
          ),
        ),
      ),
    );
  }
}
