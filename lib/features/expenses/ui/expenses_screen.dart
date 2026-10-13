import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/empty_state.dart';
import '../../categories/category.dart';
import '../../categories/cubit/category_cubit.dart';
import '../../categories/cubit/category_state.dart';
import '../../categories/ui/category_icon_helper.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../expense.dart';
import 'expense_form_sheet.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  void _openExpenseSheet(BuildContext context, [Expense? expense]) {
    final categoryState = context.read<CategoryCubit>().state;
    final categories =
        categoryState is CategoryLoaded ? categoryState.categories : <Category>[];

    final expenseCubit = context.read<ExpenseCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ExpenseFormSheet(
        expense: expense,
        categories: categories,
        onSave: (amountMinor, categoryId, spentOn) {
          if (expense == null) {
            expenseCubit.addExpense(
              amountMinor: amountMinor,
              categoryId: categoryId,
              spentOn: spentOn,
            );
          } else {
            expenseCubit.updateExpense(expense.copyWith(
              amountMinor: amountMinor,
              categoryId: categoryId,
              spentOn: spentOn,
            ));
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Expense expense) {
    final cubit = context.read<ExpenseCubit>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete this expense of \$${expense.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              cubit.deleteExpense(expense.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatHeaderDate(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    final date = DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) return 'Today';

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
    if (isYesterday) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('expenses-screen'),
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-expense-fab'),
        onPressed: () => _openExpenseSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Expense'),
      ),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, catState) {
          final categories =
              catState is CategoryLoaded ? catState.categories : <Category>[];
          final catMap = {for (final c in categories) c.id: c};

          return BlocBuilder<ExpenseCubit, ExpenseState>(
            builder: (context, state) {
              if (state is ExpenseLoading || state is ExpenseInitial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ExpenseError) {
                return Center(
                  child: Text(
                    'Error: ${state.message}',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              }

              if (state is ExpenseLoaded) {
                if (state.expenses.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long,
                    title: 'No expenses yet',
                    message: 'Log your first expense in seconds.',
                  );
                }

                final grouped = state.groupedByDate;

                return ListView(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 84),
                  children: [
                    // Summary Total Card
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Spending',
                                  style: theme.textTheme.labelLarge
                                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${state.totalAmount.toStringAsFixed(2)}',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.wallet,
                              size: 36,
                              color: theme.colorScheme.primary.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Daily Grouped Sections
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatHeaderDate(entry.key),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '\$${(entry.value.fold(0, (sum, e) => sum + e.amountMinor) / 100.0).toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final expense in entry.value) ...[
                        Builder(builder: (context) {
                          final category = catMap[expense.categoryId];
                          final icon = category != null
                              ? CategoryIconHelper.getIcon(category.icon)
                              : Icons.receipt;
                          final color = category != null
                              ? Color(category.color)
                              : theme.colorScheme.primary;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.18),
                                child: Icon(icon, color: color),
                              ),
                              title: Text(
                                category?.name ?? 'Uncategorized',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '\$${expense.amount.toStringAsFixed(2)}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    tooltip: 'Edit',
                                    onPressed: () => _openExpenseSheet(context, expense),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    tooltip: 'Delete',
                                    onPressed: () => _confirmDelete(context, expense),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
