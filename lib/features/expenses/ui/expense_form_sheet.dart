import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../categories/category.dart';
import '../../categories/ui/category_icon_helper.dart';
import '../expense.dart';

class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({
    super.key,
    this.expense,
    required this.categories,
    required this.onSave,
  });

  final Expense? expense;
  final List<Category> categories;
  final void Function(int amountMinor, String categoryId, DateTime spentOn) onSave;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  late final TextEditingController _amountController;
  late String _selectedCategoryId;
  late DateTime _selectedDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initialAmount = widget.expense != null
        ? (widget.expense!.amountMinor / 100.0).toStringAsFixed(2)
        : '';
    _amountController = TextEditingController(text: initialAmount);
    _selectedCategoryId = widget.expense?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : '');
    _selectedDate = widget.expense?.spentOn ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    final text = _amountController.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(text);

    if (parsed == null || parsed <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount greater than 0');
      return;
    }

    if (_selectedCategoryId.isEmpty) {
      setState(() => _errorMessage = 'Please select a category');
      return;
    }

    final amountMinor = (parsed * 100).round();
    widget.onSave(amountMinor, _selectedCategoryId, _selectedDate);
    Navigator.of(context).pop();
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
    if (isYesterday) return 'Yesterday';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.expense != null;

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
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E4F0),
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
                  isEditing ? 'Edit Expense' : 'Log Expense',
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

            // Expense Badge Pill (Inspired by Mockup toggle tabs)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.expenseContainer,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.expense),
                      SizedBox(width: 6),
                      Text(
                        'Add Expense',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Amount Input Field
            TextField(
              key: const Key('expense-amount-field'),
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                labelText: 'Amount',
                hintText: '0.00',
                errorText: _errorMessage,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),

            // Date Picker Row
            Row(
              children: [
                Text(
                  'Date:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_rounded, size: 15),
                  label: Text(
                    _formatDateLabel(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.primary,
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Category Selection
            Text(
              'Select Category',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.categories.map((cat) {
                final isSelected = cat.id == _selectedCategoryId;
                final icon = CategoryIconHelper.getIcon(cat.icon);
                final color = Color(cat.color);

                return FilterChip(
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  avatar: CircleAvatar(
                    backgroundColor: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : color.withValues(alpha: 0.2),
                    child: Icon(
                      icon,
                      size: 15,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                  label: Text(
                    cat.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryId = cat.id;
                      _errorMessage = null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Save Action Button
            FilledButton.icon(
              key: const Key('save-expense-btn'),
              onPressed: _submit,
              icon: const Icon(Icons.check_rounded),
              label: Text(isEditing ? 'Save Changes' : 'Save Expense'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
