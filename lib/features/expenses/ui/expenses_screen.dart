import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../../../core/theme/widgets.dart';
import '../../categories/category.dart';
import '../../categories/cubit/category_cubit.dart';
import '../../categories/cubit/category_state.dart';
import '../../categories/ui/category_icon_helper.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../expense.dart';
import 'expense_form_sheet.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Home: blue "spent this month" card and the transaction list.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context, Expense expense) async {
    final result = await confirmDeleteExpense(context, expense);
    if (result && context.mounted) context.read<ExpenseCubit>().deleteExpense(expense.id);
    return false; // the list reloads from the cubit
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final router = GoRouter.maybeOf(context);

    return Scaffold(
      key: const Key('expenses-screen'),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, catState) {
            final categories = catState is CategoryLoaded ? catState.categories : <Category>[];
            final catMap = {for (final c in categories) c.id: c};

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

                final expenses = state.expenses;
                return ListView(
                  padding: const EdgeInsets.only(bottom: 130),
                  children: [
                    header,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 22, AppSpace.gutter, 0),
                      child: _SpentCard(expenses: expenses),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 26, AppSpace.gutter, 6),
                      child: Text('Transactions', style: AppType.title.copyWith(color: scheme.onSurface)),
                    ),
                    if (expenses.isEmpty)
                      _EmptyTransactions(onAdd: () => showExpenseSheet(context))
                    else
                      for (final e in expenses)
                        _TransactionRow(
                          expense: e,
                          category: catMap[e.categoryId],
                          onTap: () => showExpenseSheet(context, expense: e),
                          onDelete: () => _confirmDelete(context, e),
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

/// Shared delete confirmation (list swipe and the edit screen).
Future<bool> confirmDeleteExpense(BuildContext context, Expense expense) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete expense?', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('This removes the ${Money.withLabel(expense.amountMinor)} expense.'),
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

class _SpentCard extends StatelessWidget {
  const _SpentCard({required this.expenses});
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = isDarkOf(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    var month = 0, todayTotal = 0, week = 0;
    for (final e in expenses) {
      final d = DateTime(e.spentOn.year, e.spentOn.month, e.spentOn.day);
      if (d.year == now.year && d.month == now.month) month += e.amountMinor;
      if (d == today) todayTotal += e.amountMinor;
      if (!d.isBefore(weekStart) && !d.isAfter(today)) week += e.amountMinor;
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
            'Spent in ${_months[now.month - 1]}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onPrimaryMuted),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: Money.format(month)),
                const TextSpan(
                  text: '  ${Money.currencyLabel}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onPrimaryMuted),
                ),
              ]),
              style: AppType.heroAmount,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _Stat(icon: Icons.today_rounded, label: 'Today', minor: todayTotal)),
              const SizedBox(width: 12),
              Expanded(child: _Stat(icon: Icons.bar_chart_rounded, label: 'This week', minor: week)),
            ],
          ),
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
                Money.withLabel(minor),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 28, AppSpace.gutter, 0),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_rounded, size: 32, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text('No expenses yet', style: AppType.title.copyWith(color: scheme.onSurface)),
          const SizedBox(height: 6),
          Text(
            'Tap + to log what you spend. Your month will take shape here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.45, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('add-first-expense'),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add your first expense'),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
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
