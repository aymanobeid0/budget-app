import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/widgets.dart';
import '../../categories/category.dart';
import '../../categories/cubit/category_cubit.dart';
import '../../categories/cubit/category_state.dart';
import '../../categories/ui/category_icon_helper.dart';
import '../cubit/expense_cubit.dart';
import '../expense.dart';
import 'expenses_screen.dart' show confirmDeleteExpense;

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Opens the full-screen add/edit expense page. Used by the nav bar's add
/// button and by tapping a transaction.
Future<void> showExpenseSheet(BuildContext context, {Expense? expense}) {
  final categoryState = context.read<CategoryCubit>().state;
  final categories = categoryState is CategoryLoaded ? categoryState.categories : <Category>[];
  final expenseCubit = context.read<ExpenseCubit>();

  return Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => ExpenseFormSheet(
      expense: expense,
      categories: categories,
      onSave: (amountMinor, categoryId, spentOn) {
        if (expense == null) {
          expenseCubit.addExpense(amountMinor: amountMinor, categoryId: categoryId, spentOn: spentOn);
        } else {
          expenseCubit.updateExpense(
            expense.copyWith(amountMinor: amountMinor, categoryId: categoryId, spentOn: spentOn),
          );
        }
      },
      onDelete: expense == null ? null : () => expenseCubit.deleteExpense(expense.id),
    ),
  ));
}

/// Add / edit expense page (kept under its original name for callers).
class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({
    super.key,
    this.expense,
    required this.categories,
    required this.onSave,
    this.onDelete,
  });

  final Expense? expense;
  final List<Category> categories;
  final void Function(int amountMinor, String categoryId, DateTime spentOn) onSave;
  final VoidCallback? onDelete;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  late final TextEditingController _amount;
  late String _categoryId;
  late DateTime _date;
  late DateTime _weekStart;
  String? _amountError;
  String? _categoryError;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _mondayOf(DateTime d) => _day(d).subtract(Duration(days: d.weekday - 1));

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _amount = TextEditingController(text: e != null ? Money.format(e.amountMinor).replaceAll(',', '') : '');
    _categoryId = e?.categoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : '');
    _date = _day(e?.spentOn ?? DateTime.now());
    _weekStart = _mondayOf(_date);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    setState(() {
      _amountError = parsed == null || parsed <= 0 ? 'Enter an amount greater than 0' : null;
      _categoryError = _categoryId.isEmpty ? 'Pick a category' : null;
    });
    if (_amountError != null || _categoryError != null) return;
    widget.onSave((parsed! * 100).round(), _categoryId, _date);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final e = widget.expense;
    if (e == null) return;
    if (await confirmDeleteExpense(context, e) && mounted) {
      widget.onDelete?.call();
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _date = _day(picked);
        _weekStart = _mondayOf(_date);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEditing = widget.expense != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: isEditing ? 'Edit Expense' : 'Add Expense',
              leading: SquareIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Back',
                onTap: () => Navigator.of(context).pop(),
              ),
              trailing: isEditing
                  ? SquareIconButton(
                      key: const Key('delete-expense-btn'),
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Delete expense',
                      color: AppColors.expense,
                      onTap: _delete,
                    )
                  : null,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 22, AppSpace.gutter, 16),
                children: [
                  _WeekStrip(
                    weekStart: _weekStart,
                    selected: _date,
                    onPrev: () => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7))),
                    onNext: _weekStart.add(const Duration(days: 7)).isAfter(_day(DateTime.now()))
                        ? null
                        : () => setState(() => _weekStart = _weekStart.add(const Duration(days: 7))),
                    onPick: (d) => setState(() => _date = d),
                    onTitleTap: _pickDate,
                  ),
                  const SizedBox(height: 24),
                  Text('Amount', style: AppType.fieldLabel.copyWith(color: scheme.onSurface)),
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('expense-amount-field'),
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    autofocus: !isEditing,
                    style: AppType.entryAmount.copyWith(color: scheme.onSurface),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: '0',
                      errorText: _amountError,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 10),
                        child: Text(
                          Money.currencyLabel,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Category', style: AppType.fieldLabel.copyWith(color: scheme.onSurface)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final c in widget.categories)
                        _CategoryChip(
                          category: c,
                          selected: c.id == _categoryId,
                          onTap: () => setState(() {
                            _categoryId = c.id;
                            _categoryError = null;
                          }),
                        ),
                    ],
                  ),
                  if (_categoryError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_categoryError!, style: const TextStyle(fontSize: 13, color: AppColors.expense)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 8, AppSpace.gutter, 20),
              child: PrimaryButton(
                key: const Key('save-expense-btn'),
                label: isEditing ? 'Save Changes' : 'Add Expense',
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.weekStart,
    required this.selected,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
    required this.onTitleTap,
  });

  final DateTime weekStart;
  final DateTime selected;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onTitleTap;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mid = weekStart.add(const Duration(days: 3));

    return Container(
      key: const Key('week-strip'),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(tooltip: 'Previous week', onPressed: onPrev, icon: const Icon(Icons.chevron_left_rounded)),
              Expanded(
                child: TextButton(
                  onPressed: onTitleTap,
                  style: TextButton.styleFrom(foregroundColor: scheme.onSurface),
                  child: Text(
                    '${_months[mid.month - 1]} ${mid.year}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(tooltip: 'Next week', onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Text(
                    _letters[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(child: _day(context, weekStart.add(Duration(days: i)), today)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _day(BuildContext context, DateTime d, DateTime today) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = d == selected;
    final isFuture = d.isAfter(today);

    return Center(
      child: Semantics(
        selected: isSelected,
        button: true,
        label: '${d.day} ${_months[d.month - 1]}',
        child: InkWell(
          key: Key('day-${d.year}-${d.month}-${d.day}'),
          customBorder: const CircleBorder(),
          onTap: isFuture ? null : () => onPick(d),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? scheme.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${d.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isFuture ? scheme.onSurfaceVariant.withValues(alpha: 0.5) : scheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.selected, required this.onTap});
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(category.color);
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CategoryIconHelper.getIcon(category.icon),
                size: 17,
                color: selected
                    ? Colors.white
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Color.lerp(color, Colors.white, 0.35)
                        : CategoryPalette.onTint(color)),
              ),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? Colors.white : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
