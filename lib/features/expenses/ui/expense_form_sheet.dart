import 'package:flutter/material.dart';

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
    final isEditing = widget.expense != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Expense' : 'Log Expense',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('expense-amount-field'),
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '\$ ',
                labelText: 'Amount',
                hintText: '0.00',
                errorText: _errorMessage,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Date:', style: theme.textTheme.titleSmall),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_formatDateLabel(_selectedDate)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Select Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.categories.map((cat) {
                final isSelected = cat.id == _selectedCategoryId;
                final icon = CategoryIconHelper.getIcon(cat.icon);
                final color = Color(cat.color);

                return FilterChip(
                  selected: isSelected,
                  avatar: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  label: Text(cat.name),
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
            FilledButton.icon(
              key: const Key('save-expense-btn'),
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: Text(isEditing ? 'Save Changes' : 'Save Expense'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
