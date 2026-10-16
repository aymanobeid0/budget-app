import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../categories/category.dart';
import '../../categories/cubit/category_cubit.dart';
import '../../categories/cubit/category_state.dart';
import '../../categories/ui/category_icon_helper.dart';
import '../cubit/expense_cubit.dart';
import '../expense.dart';

/// Opens the add/edit expense sheet. Used by the nav bar's raised add button
/// and by tapping an existing expense row.
Future<void> showExpenseSheet(BuildContext context, {Expense? expense}) {
  final categoryState = context.read<CategoryCubit>().state;
  final categories =
      categoryState is CategoryLoaded ? categoryState.categories : <Category>[];
  final expenseCubit = context.read<ExpenseCubit>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
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
    final initial = widget.expense;
    _amountController = TextEditingController(
      text: initial != null ? Money.format(initial.amountMinor).replaceAll(',', '') : '',
    );
    _amountController.addListener(() => setState(() {}));
    _selectedCategoryId = initial?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : '');
    _selectedDate = initial?.spentOn ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int? get _parsedMinor {
    final parsed = double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return null;
    return (parsed * 100).round();
  }

  void _press(String key) {
    var text = _amountController.text;
    if (key == '⌫') {
      if (text.isNotEmpty) text = text.substring(0, text.length - 1);
    } else if (key == '.') {
      if (!text.contains('.')) text = text.isEmpty ? '0.' : '$text.';
    } else {
      final dot = text.indexOf('.');
      if (dot != -1 && text.length - dot > 2) return; // max 2 decimals
      if (text == '0') text = '';
      if (text.replaceAll('.', '').length >= 9) return;
      text = '$text$key';
    }
    _amountController.text = text;
    _amountController.selection = TextSelection.collapsed(offset: text.length);
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    final minor = _parsedMinor;
    if (minor == null) {
      setState(() => _errorMessage = 'Enter an amount greater than 0');
      return;
    }
    if (_selectedCategoryId.isEmpty) {
      setState(() => _errorMessage = 'Pick a category');
      return;
    }
    widget.onSave(minor, _selectedCategoryId, _selectedDate);
    Navigator.of(context).pop();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.expense != null;
    final now = DateTime.now();
    final isToday = _sameDay(_selectedDate, now);
    final isYesterday = _sameDay(_selectedDate, now.subtract(const Duration(days: 1)));
    final minor = _parsedMinor;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        boxShadow: AppShadows.sheet,
      ),
      padding: EdgeInsets.only(
        left: AppSpace.xl,
        right: AppSpace.xl,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.xxl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.handle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'Edit expense' : 'New expense',
                    style: AppType.title.copyWith(color: scheme.onSurface),
                  ),
                ),
                _CircleIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),

            // Amount
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFEDEDE9)),
              ),
              child: Column(
                children: [
                  Text(
                    'AMOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  TextField(
                    key: const Key('expense-amount-field'),
                    controller: _amountController,
                    keyboardType: TextInputType.none, // on-screen keypad below
                    textAlign: TextAlign.center,
                    showCursor: true,
                    cursorColor: AppColors.primary,
                    cursorWidth: 2,
                    style: AppType.entryAmount.copyWith(color: scheme.onSurface),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '0',
                      hintStyle: AppType.entryAmount.copyWith(color: AppColors.borderDashed),
                      suffixText: Money.currencyLabel,
                      suffixStyle: AppType.label.copyWith(fontSize: 17),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 13, color: AppColors.expense),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),

            // Category
            const _SectionLabel('Category'),
            LayoutBuilder(builder: (context, constraints) {
              final w = (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in widget.categories)
                    SizedBox(
                      width: w,
                      child: _CategoryChoice(
                        category: cat,
                        selected: cat.id == _selectedCategoryId,
                        onTap: () => setState(() {
                          _selectedCategoryId = cat.id;
                          _errorMessage = null;
                        }),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: AppSpace.lg),

            // Date
            const _SectionLabel('Date'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DateChip(
                  label: 'Today',
                  selected: isToday,
                  onTap: () => setState(() => _selectedDate = now),
                ),
                _DateChip(
                  label: 'Yesterday',
                  selected: isYesterday,
                  onTap: () => setState(
                    () => _selectedDate = now.subtract(const Duration(days: 1)),
                  ),
                ),
                _DateChip(
                  label: isToday || isYesterday
                      ? 'Pick date'
                      : '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  icon: Icons.calendar_today_outlined,
                  selected: !isToday && !isYesterday,
                  onTap: _pickDate,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),

            // Keypad
            _Keypad(onKey: _press),
            const SizedBox(height: AppSpace.lg),

            // Save
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppShadows.fab,
              ),
              child: FilledButton.icon(
                key: const Key('save-expense-btn'),
                onPressed: _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  minor == null
                      ? (isEditing ? 'Save changes' : 'Save expense')
                      : 'Save · ${Money.withLabel(minor)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: AppType.section.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? AppColors.darkSurfaceSubtle : AppColors.background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({required this.category, required this.selected, required this.onTap});
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(category.color);
    final bg = selected ? AppColors.ink : scheme.surface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: selected ? null : Border.all(color: scheme.outline),
        boxShadow: selected
            ? AppShadows.inkChip
            : const [BoxShadow(color: Color(0x0D111111), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CategoryIconHelper.getIcon(category.icon),
                  size: 18,
                  color: selected
                      ? Color.lerp(color, Colors.white, 0.3)
                      : CategoryPalette.onTint(color),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    category.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? Colors.white : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? AppColors.primary : scheme.onSurface;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      shape: StadiumBorder(
        side: selected ? BorderSide.none : BorderSide(color: scheme.outline),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected && icon == null) ...[
                Icon(Icons.check_rounded, size: 16, color: fg),
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});
  final ValueChanged<String> onKey;

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = Theme.of(context).colorScheme.onSurface;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        for (final k in _keys)
          _Key(
            label: k,
            flat: k == '.' || k == '⌫',
            onTap: () => onKey(k),
            background: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle,
            foreground: fg,
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.flat,
    required this.onTap,
    required this.background,
    required this.foreground,
  });
  final String label;
  final bool flat;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == '⌫';
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: flat ? null : const [BoxShadow(color: Color(0xFFDCDCD7), offset: Offset(0, 1))],
      ),
      child: Material(
        color: flat ? Colors.transparent : background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Center(
            child: isBackspace
                ? Icon(Icons.backspace_outlined, size: 22, color: foreground, semanticLabel: 'Delete digit')
                : Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontSize: 22,
                      color: foreground,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
