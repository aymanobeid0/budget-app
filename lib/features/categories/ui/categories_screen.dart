import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
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
      backgroundColor: Colors.transparent,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Delete Category', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: const Key('categories-screen'),
      appBar: AppBar(
        title: const Text('Categories'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
              ),
              child: Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          boxShadow: AppShadows.fab,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _openCategorySheet(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Add Category',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
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
                icon: Icons.category_rounded,
                title: 'No Categories',
                message: 'Tap the button below to create your first category.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 96),
              itemCount: state.categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final icon = CategoryIconHelper.getIcon(category.icon);
                final color = Color(category.color);

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                      width: 1,
                    ),
                    boxShadow: AppShadows.card,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    title: Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit',
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          onPressed: () => _openCategorySheet(context, category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: 'Delete',
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
