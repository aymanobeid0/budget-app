import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../category.dart';
import 'category_icon_helper.dart';

class CategoryFormSheet extends StatefulWidget {
  const CategoryFormSheet({
    super.key,
    this.category,
    required this.onSave,
  });

  final Category? category;
  final void Function(String name, String icon, int color) onSave;

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late int _selectedColor;

  static const List<int> _availableColors = [
    0xFF042895, // Brand blue
    0xFFE97A1F, // Orange (Food)
    0xFF0F766E, // Teal (Utilities)
    0xFF3B82F6, // Blue
    0xFF4F46E5, // Indigo
    0xFFDB2777, // Pink
    0xFFE5484D, // Red
    0xFF92603A, // Brown
    0xFF16A34A, // Green
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? 'restaurant';
    _selectedColor = widget.category?.color ?? _availableColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    widget.onSave(name, _selectedIcon, _selectedColor);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.category != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.handle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Category' : 'New Category',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Name Field
            TextField(
              key: const Key('category-name-field'),
              controller: _nameController,
              autofocus: true,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Groceries, Gym, Subscriptions',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),

            // Icon Picker
            Text(
              'Select Icon',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: CategoryIconHelper.availableIcons.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final key = CategoryIconHelper.availableIcons.keys.elementAt(index);
                  final icon = CategoryIconHelper.availableIcons[key]!;
                  final isSelected = key == _selectedIcon;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = key),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : (isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: isSelected
                            ? Border.all(color: theme.colorScheme.primary, width: 2)
                            : Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                              ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Color Picker
            Text(
              'Select Color',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _availableColors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final colorVal = _availableColors[index];
                  final isSelected = colorVal == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = colorVal),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(colorVal).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Action Button
            FilledButton.icon(
              key: const Key('save-category-btn'),
              onPressed: _submit,
              icon: const Icon(Icons.check_rounded),
              label: Text(isEditing ? 'Save Changes' : 'Create Category'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
