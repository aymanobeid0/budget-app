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
import '../../income/cubit/income_cubit.dart';
import '../../income/cubit/income_state.dart';
import '../../income/income_source.dart';
import '../../settings/cubit/currency_cubit.dart';
import '../cubit/expense_cubit.dart';
import '../expense.dart';
import '../../income/income.dart';
import 'expenses_screen.dart' show confirmDeleteEntry;

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// What the Add sheet is logging.
enum EntryKind { expense, income }

/// The Add sheet opens on the kind used last, so several Income in a row
/// don't need a switch each time. Kept for the app's lifetime.
class AddSheetMemory {
  const AddSheetMemory._();

  static EntryKind lastKind = EntryKind.expense;

  @visibleForTesting
  static void reset() => lastKind = EntryKind.expense;
}

/// Opens the full-screen add/edit page. Used by the nav bar's add button and
/// by tapping an Expense or Income in a list. [kind] forces a mode;
/// otherwise a new entry opens on the mode used last.
Future<void> showExpenseSheet(BuildContext context, {Expense? expense, Income? income, EntryKind? kind}) {
  final categoryState = context.read<CategoryCubit>().state;
  final categories = categoryState is CategoryLoaded ? categoryState.categories : <Category>[];
  final expenseCubit = context.read<ExpenseCubit>();
  final incomeCubit = maybeIncomeCubit(context);
  final currency = context.read<CurrencyCubit>().state;

  // Sources the picker offers: the active ones, plus a deleted one the edited
  // Income still points at, so it shows as picked.
  List<IncomeSource> pickable(IncomeState state) {
    if (state is! IncomeLoaded) return const [];
    final current = income == null ? null : state.sourceById[income.sourceId];
    return [
      ...state.sources,
      if (current != null && current.isDeleted) current,
    ];
  }

  Widget sheet(List<IncomeSource> sources) => ExpenseFormSheet(
      expense: expense,
      income: income,
      initialKind: kind,
      categories: categories,
      incomeSources: sources,
      currency: currency,
      onSaveIncome: incomeCubit == null
          ? null
          : (amountMinor, sourceId, paidOn) => income == null
              ? incomeCubit.addIncome(amountMinor: amountMinor, sourceId: sourceId, paidOn: paidOn)
              : incomeCubit.updateIncome(income.copyWith(amountMinor: amountMinor, sourceId: sourceId, paidOn: paidOn)),
      onSave: (amountMinor, categoryId, spentOn) {
        if (expense == null) {
          expenseCubit.addExpense(amountMinor: amountMinor, categoryId: categoryId, spentOn: spentOn);
        } else {
          expenseCubit.updateExpense(
            expense.copyWith(amountMinor: amountMinor, categoryId: categoryId, spentOn: spentOn),
          );
        }
      },
      onDelete: expense != null
          ? () => expenseCubit.deleteExpense(expense.id)
          : (income != null ? () => incomeCubit?.deleteIncome(income.id) : null),
    );

  return Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    // Rebuilt as sources load or change, so the picker is never a stale
    // snapshot (e.g. opened right after launch or an account switch).
    builder: (_) => incomeCubit == null
        ? sheet(const [])
        : BlocBuilder<IncomeCubit, IncomeState>(
            bloc: incomeCubit,
            builder: (_, state) => sheet(pickable(state)),
          ),
  ));
}

/// Add / edit page for an Expense or an Income (kept under its original
/// name for callers). A new entry can switch between the two when
/// [onSaveIncome] is given.
class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({
    super.key,
    this.expense,
    this.income,
    this.initialKind,
    required this.categories,
    this.incomeSources = const [],
    required this.onSave,
    this.onSaveIncome,
    this.onDelete,
    this.currency = Currency.mru,
  });

  final Expense? expense;
  final Income? income;
  final EntryKind? initialKind;
  final List<Category> categories;
  final List<IncomeSource> incomeSources;
  final void Function(int amountMinor, String categoryId, DateTime spentOn) onSave;
  final void Function(int amountMinor, String sourceId, DateTime paidOn)? onSaveIncome;
  final VoidCallback? onDelete;

  /// Labels the amount field.
  final Currency currency;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  late final TextEditingController _amount;
  late EntryKind _kind;
  late String _categoryId;
  String _sourceId = '';
  late DateTime _date;
  late DateTime _weekStart;
  String? _amountError;
  String? _pickError;

  bool get _isIncome => _kind == EntryKind.income;
  bool get _isEditing => widget.expense != null || widget.income != null;
  bool get _canSwitch => !_isEditing && widget.onSaveIncome != null;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _mondayOf(DateTime d) => _day(d).subtract(Duration(days: d.weekday - 1));

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    final i = widget.income;
    final amountMinor = e?.amountMinor ?? i?.amountMinor;
    _amount = TextEditingController(text: amountMinor != null ? Money.format(amountMinor).replaceAll(',', '') : '');
    _categoryId = e?.categoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : '');
    _sourceId = i?.sourceId ?? '';
    _kind = i != null
        ? EntryKind.income
        : (_canSwitch ? (widget.initialKind ?? AddSheetMemory.lastKind) : EntryKind.expense);
    _date = _day(e?.spentOn ?? i?.paidOn ?? DateTime.now());
    _weekStart = _mondayOf(_date);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    final pickedId = _isIncome ? _sourceId : _categoryId;
    setState(() {
      _amountError = parsed == null || parsed <= 0 ? 'Enter an amount greater than 0' : null;
      _pickError = pickedId.isEmpty ? (_isIncome ? 'Pick an Income Source' : 'Pick a category') : null;
    });
    if (_amountError != null || _pickError != null) return;
    final amountMinor = (parsed! * 100).round();
    if (_isIncome) {
      widget.onSaveIncome!(amountMinor, _sourceId, _date);
    } else {
      widget.onSave(amountMinor, _categoryId, _date);
    }
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  void _switchKind(EntryKind kind) {
    AddSheetMemory.lastKind = kind;
    setState(() {
      _kind = kind;
      _pickError = null;
    });
  }

  /// Chips for the current mode: Categories for an Expense, Income Sources
  /// for an Income. The two lists never mix.
  List<Widget> _pickerChips() {
    if (_isIncome) {
      return [
        for (final s in widget.incomeSources)
          _PickerChip(
            name: s.name,
            icon: s.icon,
            color: s.color,
            selected: s.id == _sourceId,
            onTap: () => setState(() {
              _sourceId = s.id;
              _pickError = null;
            }),
          ),
      ];
    }
    return [
      for (final c in widget.categories)
        _PickerChip(
          name: c.name,
          icon: c.icon,
          color: c.color,
          selected: c.id == _categoryId,
          onTap: () => setState(() {
            _categoryId = c.id;
            _pickError = null;
          }),
        ),
    ];
  }

  Future<void> _delete() async {
    final amountMinor = widget.expense?.amountMinor ?? widget.income?.amountMinor;
    if (amountMinor == null) return;
    final noun = _isIncome ? 'income' : 'expense';
    if (await confirmDeleteEntry(context, noun: noun, amountMinor: amountMinor, currency: widget.currency) &&
        mounted) {
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
    final isEditing = _isEditing;
    final noun = _isIncome ? 'Income' : 'Expense';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: isEditing ? 'Edit $noun' : 'Add $noun',
              leading: SquareIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Back',
                onTap: () => Navigator.of(context).pop(),
              ),
              trailing: isEditing
                  ? SquareIconButton(
                      key: const Key('delete-expense-btn'),
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Delete ${noun.toLowerCase()}',
                      color: AppColors.expense,
                      onTap: _delete,
                    )
                  : null,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 22, AppSpace.gutter, 16),
                children: [
                  if (_canSwitch) ...[
                    SegmentedButton<EntryKind>(
                      key: const Key('entry-kind-switch'),
                      segments: const [
                        ButtonSegment(
                          value: EntryKind.expense,
                          label: Text('Expense', key: Key('entry-kind-expense')),
                        ),
                        ButtonSegment(
                          value: EntryKind.income,
                          label: Text('Income', key: Key('entry-kind-income')),
                        ),
                      ],
                      selected: {_kind},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => _switchKind(s.first),
                    ),
                    const SizedBox(height: 18),
                  ],
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
                          widget.currency.code,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isIncome ? 'Income Source' : 'Category',
                    style: AppType.fieldLabel.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, runSpacing: 10, children: _pickerChips()),
                  if (_pickError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_pickError!, style: const TextStyle(fontSize: 13, color: AppColors.expense)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 8, AppSpace.gutter, 20),
              child: PrimaryButton(
                key: const Key('save-expense-btn'),
                label: isEditing ? 'Save Changes' : 'Add $noun',
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
      decoration: raisedDecoration(context, radius: 18, shadow: AppShadows.panel),
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

/// A Category or Income Source chip in the Add sheet picker.
class _PickerChip extends StatelessWidget {
  const _PickerChip({
    required this.name,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final String icon;
  final int color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(this.color);
    return Material(
      color: selected ? scheme.primary : raisedColor(context),
      elevation: selected ? 0 : raisedElevation(context),
      shadowColor: raisedShadowColor,
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
                CategoryIconHelper.getIcon(icon),
                size: 17,
                color: selected
                    ? Colors.white
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Color.lerp(color, Colors.white, 0.35)
                        : CategoryPalette.onTint(color)),
              ),
              const SizedBox(width: 8),
              Text(
                name,
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
