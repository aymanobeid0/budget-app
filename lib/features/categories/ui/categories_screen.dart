import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/widgets.dart';
import '../../expenses/cubit/expense_cubit.dart';
import '../../expenses/cubit/expense_state.dart';
import '../category.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import 'category_form_sheet.dart';
import 'category_icon_helper.dart';

/// Categories as a menu: solid colored squares, a line between rows, a "⋯"
/// menu for edit/delete and an "Add category" row at the end.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  void _openCategorySheet(BuildContext context, [Category? category]) {
    final cubit = context.read<CategoryCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true, // above the nav bar, so Save is never covered
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFormSheet(
        category: category,
        onSave: (name, icon, color) {
          if (category == null) {
            cubit.addCategory(name: name, icon: icon, color: color);
          } else {
            cubit.updateCategory(category.copyWith(name: name, icon: icon, color: color));
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    final cubit = context.read<CategoryCubit>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete category?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('"${category.name}" will be removed from your list.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
              minimumSize: const Size(88, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              cubit.deleteCategory(category.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// This month's expense count per category, when expenses are available.
  Map<String, int> _monthCounts(BuildContext context) {
    ExpenseState? state;
    try {
      state = context.watch<ExpenseCubit>().state;
    } catch (_) {
      return const {}; // screen used without the expenses feature (tests)
    }
    if (state is! ExpenseLoaded) return const {};
    final now = DateTime.now();
    final counts = <String, int>{};
    for (final e in state.expenses) {
      if (e.spentOn.year == now.year && e.spentOn.month == now.month) {
        counts[e.categoryId] = (counts[e.categoryId] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final counts = _monthCounts(context);
    // Reached from Profile; standalone (tests) there is nothing to go back to.
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      key: const Key('categories-screen'),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            final header = ScreenHeader(
              title: 'Categories',
              leading: canPop
                  ? IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.pop(),
                    )
                  : null,
              trailing: SquareIconButton(
                key: const Key('add-category-btn'),
                icon: Icons.add_rounded,
                tooltip: 'Add category',
                onTap: () => _openCategorySheet(context),
              ),
            );

            if (state is CategoryLoading || state is CategoryInitial) {
              return Column(children: [header, const Expanded(child: Center(child: CircularProgressIndicator()))]);
            }
            if (state is CategoryError) {
              return Column(children: [
                header,
                Expanded(child: Center(child: Text('Error: ${state.message}', style: TextStyle(color: scheme.error)))),
              ]);
            }
            if (state is! CategoryLoaded) return const SizedBox.shrink();

            final categories = state.categories;
            return ListView(
              padding: const EdgeInsets.only(bottom: 130),
              children: [
                header,
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 18, AppSpace.gutter, 8),
                  child: Text(
                    categories.isEmpty
                        ? 'No categories yet'
                        : '${categories.length} ${categories.length == 1 ? 'category' : 'categories'} · tap one to edit',
                    style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                  ),
                ),
                Padding(
                  key: const Key('categories-menu'),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final c in categories) ...[
                        _CategoryMenuItem(
                          category: c,
                          count: counts[c.id] ?? 0,
                          onTap: () => _openCategorySheet(context, c),
                          onEdit: () => _openCategorySheet(context, c),
                          onDelete: () => _confirmDelete(context, c),
                        ),
                        Divider(height: 1, indent: 8 + 36 + 14, endIndent: 8, color: scheme.outlineVariant),
                      ],
                      MenuRow(
                        key: const Key('add-category-row'),
                        icon: Icons.add_rounded,
                        color: scheme.primary,
                        title: 'Add category',
                        showDivider: false,
                        onTap: () => _openCategorySheet(context),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryMenuItem extends StatelessWidget {
  const _CategoryMenuItem({
    required this.category,
    required this.count,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MenuRow(
      key: Key('category-item-${category.id}'),
      icon: CategoryIconHelper.getIcon(category.icon),
      color: Color(category.color),
      title: category.name,
      subtitle: count == 0 ? 'No expenses this month' : '$count ${count == 1 ? 'expense' : 'expenses'} this month',
      showDivider: false,
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        tooltip: 'More options',
        icon: Icon(Icons.more_horiz_rounded, color: scheme.onSurfaceVariant),
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        elevation: 6,
        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'edit',
            child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Text('Edit')]),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
              SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: AppColors.expense)),
            ]),
          ),
        ],
      ),
    );
  }
}
