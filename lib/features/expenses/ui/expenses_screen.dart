import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/empty_state.dart';
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
const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context, Expense expense) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete expense?', style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text('This removes the ${Money.withLabel(expense.amountMinor)} expense.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
              minimumSize: const Size(88, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      context.read<ExpenseCubit>().deleteExpense(expense.id);
    }
    return false; // the stream update removes the row
  }

  String _formatHeaderDate(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final label = '${_weekdays[date.weekday - 1]}, ${date.day} ${_shortMonths[date.month - 1]}';
    return date.year == now.year ? label : '$label ${date.year}';
  }

  String _time(DateTime t) {
    final local = t.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: const Key('expenses-screen'),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CategoryCubit, CategoryState>(
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
                    child: Text('Error: ${state.message}', style: TextStyle(color: scheme.error)),
                  );
                }
                if (state is! ExpenseLoaded) return const SizedBox.shrink();

                if (state.expenses.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No expenses yet',
                    message: 'Log what you spend in a few taps. Your month will take shape here.',
                    action: FilledButton.icon(
                      key: const Key('add-first-expense'),
                      onPressed: () => showExpenseSheet(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add your first expense'),
                    ),
                  );
                }

                final now = DateTime.now();
                final monthExpenses = state.expenses
                    .where((e) => e.spentOn.year == now.year && e.spentOn.month == now.month)
                    .toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xl, AppSpace.gutter, 120),
                  children: [
                    Row(children: [_MonthPill(label: '${_months[now.month - 1]} ${now.year}')]),
                    const SizedBox(height: AppSpace.lg),
                    _MonthSummaryCard(expenses: monthExpenses, categories: catMap),
                    for (final entry in state.groupedByDate.entries) ...[
                      _SectionHeader(
                        label: _formatHeaderDate(entry.key),
                        totalMinor: entry.value.fold(0, (s, e) => s + e.amountMinor),
                      ),
                      _ElevatedCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: Column(
                          children: [
                            for (var i = 0; i < entry.value.length; i++)
                              _ExpenseRow(
                                expense: entry.value[i],
                                category: catMap[entry.value[i].categoryId],
                                subtitle: _time(entry.value[i].createdAt),
                                showDivider: i < entry.value.length - 1,
                                onTap: () => showExpenseSheet(context, expense: entry.value[i]),
                                onDelete: () => _confirmDelete(context, entry.value[i]),
                              ),
                          ],
                        ),
                      ),
                    ],
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

class _ElevatedCard extends StatelessWidget {
  const _ElevatedCard({super.key, required this.child, this.padding, this.radius = AppRadius.lg, this.shadow});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: isDark ? null : (shadow ?? AppShadows.card),
        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: child,
    );
  }
}

class _MonthPill extends StatelessWidget {
  const _MonthPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: scheme.onSurface)),
        ],
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({required this.expenses, required this.categories});
  final List<Expense> expenses;
  final Map<String, Category> categories;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = expenses.fold<int>(0, (s, e) => s + e.amountMinor);

    // Per-category totals, biggest first; top 4 named, the rest as "Other".
    final byCat = <String, int>{};
    for (final e in expenses) {
      byCat[e.categoryId] = (byCat[e.categoryId] ?? 0) + e.amountMinor;
    }
    final sorted = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(4).toList();
    final otherMinor = sorted.skip(4).fold<int>(0, (s, e) => s + e.value);

    final segments = <_Segment>[
      for (final e in top)
        _Segment(
          label: categories[e.key]?.name ?? 'Other',
          color: categories[e.key] != null ? Color(categories[e.key]!.color) : CategoryPalette.other,
          minor: e.value,
        ),
      if (otherMinor > 0) _Segment(label: 'Other', color: CategoryPalette.other, minor: otherMinor),
    ];

    return _ElevatedCard(
      key: const Key('month-summary-card'),
      padding: const EdgeInsets.all(AppSpace.xl),
      radius: AppRadius.xl,
      shadow: AppShadows.heroCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Spent this month', style: AppType.label.copyWith(color: scheme.onSurfaceVariant)),
              ),
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${expenses.length} ${expenses.length == 1 ? 'expense' : 'expenses'}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: Money.format(total)),
                  TextSpan(
                    text: '  ${Money.currencyLabel}',
                    style: TextStyle(fontSize: 17, letterSpacing: 0, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              style: AppType.heroAmount.copyWith(color: scheme.onSurface),
            ),
          ),
          if (segments.isNotEmpty && total > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (var i = 0; i < segments.length; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(
                        flex: (segments[i].minor * 1000 ~/ total).clamp(1, 1000),
                        child: ColoredBox(color: segments[i].color),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final s in segments)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${s.label} ${(s.minor * 100 / total).round()}%',
                        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment {
  const _Segment({required this.label, required this.color, required this.minor});
  final String label;
  final Color color;
  final int minor;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.totalMinor});
  final String label;
  final int totalMinor;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppType.section.copyWith(color: color))),
          Text(Money.withLabel(totalMinor), style: AppType.sectionAmount.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.category,
    required this.subtitle,
    required this.showDivider,
    required this.onTap,
    required this.onDelete,
  });

  final Expense expense;
  final Category? category;
  final String subtitle;
  final bool showDivider;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = category != null ? Color(category!.color) : AppColors.primary;
    final icon = category != null
        ? CategoryIconHelper.getIcon(category!.icon)
        : Icons.receipt_long_outlined;

    return Dismissible(
      key: ValueKey('expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 8),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: showDivider ? Border(bottom: BorderSide(color: scheme.outlineVariant)) : null,
          ),
          child: Row(
            children: [
              CategoryIconTile(icon: icon, color: color),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? 'Uncategorized',
                      style: AppType.rowTitle.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppType.caption),
                  ],
                ),
              ),
              Text(
                Money.format(expense.amountMinor),
                style: AppType.rowAmount.copyWith(color: scheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
