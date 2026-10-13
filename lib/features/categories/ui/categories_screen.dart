import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/empty_state.dart';
import '../category.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import 'category_form_sheet.dart';
import 'category_icon_helper.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  void _openCategorySheet(BuildContext context, [Category? category]) {
    final cubit = context.read<CategoryCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CategoryFormSheet(
        category: category,
        onSave: (name, icon, color) {
          if (category == null) {
            cubit.addCategory(name: name, icon: icon, color: color);
          } else {
            cubit.updateCategory(category.copyWith(
              name: name,
              icon: icon,
              color: color,
            ));
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
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('categories-screen'),
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategorySheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading || state is CategoryInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CategoryError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }

          if (state is CategoryLoaded) {
            if (state.categories.isEmpty) {
              return const EmptyState(
                icon: Icons.category,
                title: 'No Categories',
                message: 'Tap the button below to create your first category.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 84),
              itemCount: state.categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final icon = CategoryIconHelper.getIcon(category.icon);
                final color = Color(category.color);

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.18),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit',
                          onPressed: () => _openCategorySheet(context, category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDelete(context, category),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
