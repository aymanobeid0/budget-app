import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/widgets.dart';
import '../../categories/category.dart';
import '../../categories/cubit/category_cubit.dart';
import '../../categories/cubit/category_state.dart';
import '../../categories/ui/category_form_sheet.dart';
import '../../categories/ui/category_icon_helper.dart';
import '../../income/cubit/income_cubit.dart';
import '../../income/cubit/income_state.dart';
import '../../income/income_source.dart';
import '../../settings/cubit/currency_cubit.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../expense.dart';
import '../../income/income.dart';
import 'expenses_screen.dart' show confirmDeleteEntry;

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// What the Add sheet is logging.
enum EntryKind { expense, income }

/// Opens the full-screen add/edit page. A new entry is the [kind] asked for
/// (an Expense unless Income is asked for) and can't switch to the other:
/// each add button does one job. Editing keeps the entry's own kind.
Future<void> showExpenseSheet(BuildContext context, {Expense? expense, Income? income, EntryKind? kind}) {
  final categoryCubit = context.read<CategoryCubit>();
  List<Category> categoriesOf(CategoryState s) => s is CategoryLoaded ? s.categories : <Category>[];
  final categories = categoriesOf(categoryCubit.state);
  final expenseCubit = context.read<ExpenseCubit>();
  final incomeCubit = maybeIncomeCubit(context);
  final currency = context.read<CurrencyCubit>().state;
  final lastCategoryId = _lastUsedCategoryId(expenseCubit.state, categories);

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

  Widget sheet(List<Category> categories, List<IncomeSource> sources) => ExpenseFormSheet(
      expense: expense,
      income: income,
      initialKind: kind,
      categories: categories,
      onAddCategory: (name, icon, color) => categoryCubit.addCategory(name: name, icon: icon, color: color),
      onAddSource: incomeCubit == null
          ? null
          : (name, icon, color) => incomeCubit.addSource(name: name, icon: icon, color: color),
      lastCategoryId: lastCategoryId,
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

  // On the root navigator: the page covers the tab bar and the add button,
  // whether it was opened from a tab, a list row or the add button.
  return Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    // Rebuilt as Categories and sources load or change, so the picker is
    // never a stale snapshot (e.g. opened right after launch, an account
    // switch, or one added from the picker's own + chip).
    builder: (_) => ReadablePage(
      child: BlocBuilder<CategoryCubit, CategoryState>(
        bloc: categoryCubit,
        builder: (_, catState) => incomeCubit == null
            ? sheet(categoriesOf(catState), const [])
            : BlocBuilder<IncomeCubit, IncomeState>(
                bloc: incomeCubit,
                builder: (_, state) => sheet(categoriesOf(catState), pickable(state)),
              ),
      ),
    ),
  ));
}

/// The Category of the most recently logged Expense, while that Category is
/// still in the picker; null before the first Expense. A new Expense starts
/// on it, so a run of coffees doesn't need a tap each, and nothing is filed
/// under whichever Category happens to sort first.
String? _lastUsedCategoryId(ExpenseState state, List<Category> categories) {
  if (state is! ExpenseLoaded) return null;
  final live = [for (final e in state.expenses) if (e.deletedAt == null) e];
  if (live.isEmpty) return null;
  final last = live.reduce((a, b) => b.createdAt.isAfter(a.createdAt) ? b : a);
  return categories.any((c) => c.id == last.categoryId) ? last.categoryId : null;
}

/// Add / edit page for an Expense or an Income (kept under its original
/// name for callers). A new Income needs [onSaveIncome].
class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({
    super.key,
    this.expense,
    this.income,
    this.initialKind,
    required this.categories,
    this.onAddCategory,
    this.onAddSource,
    this.lastCategoryId,
    this.incomeSources = const [],
    required this.onSave,
    this.onSaveIncome,
    this.onDelete,
    this.currency = Currency.fallback,
  });

  final Expense? expense;
  final Income? income;
  final EntryKind? initialKind;
  final List<Category> categories;

  /// Saves a Category made from the picker's + chip and returns its id (null
  /// when it failed); without it the chip is hidden. [onAddSource] is the
  /// same for Income Sources.
  final Future<String?> Function(String name, String icon, int color)? onAddCategory;
  final Future<String?> Function(String name, String icon, int color)? onAddSource;

  /// The Category a new Expense starts on; with none, nothing is picked.
  final String? lastCategoryId;
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
  late final EntryKind _kind;
  late String _categoryId;
  String _sourceId = '';
  late DateTime _date;
  late DateTime _weekStart;
  String? _amountError;
  String? _pickError;

  bool get _isIncome => _kind == EntryKind.income;
  bool get _isEditing => widget.expense != null || widget.income != null;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _mondayOf(DateTime d) => _day(d).subtract(Duration(days: d.weekday - 1));

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    final i = widget.income;
    final amountMinor = e?.amountMinor ?? i?.amountMinor;
    _amount = TextEditingController(text: amountMinor != null ? Money.format(amountMinor).replaceAll(',', '') : '');
    _categoryId = e?.categoryId ?? widget.lastCategoryId ?? '';
    _sourceId = i?.sourceId ?? '';
    _kind = i != null
        ? EntryKind.income
        : (e != null || widget.onSaveIncome == null ? EntryKind.expense : (widget.initialKind ?? EntryKind.expense));
    _date = _day(e?.spentOn ?? i?.paidOn ?? DateTime.now());
    _weekStart = _mondayOf(_date);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _amount.text.trim();
    final parsed = Money.parseMinor(text);
    final pickedId = _isIncome ? _sourceId : _categoryId;
    setState(() {
      _amountError = text.isEmpty || parsed == 0
          ? 'Enter an amount greater than 0'
          : (parsed == null ? 'Enter an amount like 450 or 12.50' : null);
      _pickError = pickedId.isEmpty ? (_isIncome ? 'Pick an Income Source' : 'Pick a Category') : null;
    });
    if (_amountError != null || _pickError != null) return;
    final amountMinor = parsed!;
    if (_isIncome) {
      widget.onSaveIncome!(amountMinor, _sourceId, _date);
    } else {
      widget.onSave(amountMinor, _categoryId, _date);
    }
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  /// Chips for the current mode: Categories for an Expense, Income Sources
  /// for an Income. The two lists never mix.
  /// Opens the name, icon and colour sheet over the form; once saved, the
  /// new Category (or Income Source) is picked. The amount and date stay.
  Future<void> _addPickable() async {
    final add = _isIncome ? widget.onAddSource : widget.onAddCategory;
    if (add == null) return;
    (String, String, int)? made;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _isIncome
          ? CategoryFormSheet(
              noun: 'Income Source',
              nameHint: 'e.g. Salary, Dental clinic',
              initialIcon: 'work',
              onSave: (name, icon, color) => made = (name, icon, color),
            )
          : CategoryFormSheet(onSave: (name, icon, color) => made = (name, icon, color)),
    );
    final values = made;
    if (values == null) return;
    final id = await add(values.$1, values.$2, values.$3);
    if (id == null || !mounted) return;
    setState(() {
      if (_isIncome) {
        _sourceId = id;
      } else {
        _categoryId = id;
      }
      _pickError = null;
    });
  }

  List<Widget> _pickerChips() {
    final addChip = (_isIncome ? widget.onAddSource : widget.onAddCategory) == null
        ? null
        : _AddChip(
            key: const Key('picker-add-chip'),
            tooltip: _isIncome ? 'New Income Source' : 'New Category',
            onTap: _addPickable,
          );
    if (_isIncome) {
      return [
        ?addChip,
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
      ?addChip,
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
                icon: Icons.adaptive.arrow_back_rounded,
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
                  Text('Amount', style: AppType.fieldLabel),
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
                    style: AppType.fieldLabel,
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

  static const _letters = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mid = weekStart.add(const Duration(days: 3));
    final media = MediaQuery.of(context);

    // Seven fixed 40px day circles in a row: past 1.4x the digits would clip,
    // so the grid caps its own text size (the month above still scales).
    return MediaQuery(
      data: media.copyWith(textScaler: media.textScaler.clamp(maxScaleFactor: 1.4)),
      child: _strip(context, scheme, today, mid),
    );
  }

  Widget _strip(BuildContext context, ColorScheme scheme, DateTime today, DateTime mid) {
    return Container(
      key: const Key('week-strip'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: panelDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              _ArrowButton(tooltip: 'Previous week', onTap: onPrev, icon: Icons.chevron_left_rounded),
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
              _ArrowButton(tooltip: 'Next week', onTap: onNext, icon: Icons.chevron_right_rounded),
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface),
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
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: isFuture ? null : () => onPick(d),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
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

/// The picker's first chip: a dashed square with a plus (Monex's "add
/// category" box) that makes a new Category or Income Source in place.
class _AddChip extends StatelessWidget {
  const _AddChip({super.key, required this.tooltip, required this.onTap});
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedBorder(color: isDarkOf(context) ? AppColors.darkBorder : AppColors.borderDashed),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.add_rounded, size: 22, color: scheme.onSurfaceVariant, semanticLabel: tooltip),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.lg)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

/// Monex's month arrow: a chevron in a small outlined square.
class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.tooltip, required this.onTap, required this.icon});
  final String tooltip;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: RaisedSurface(
            onTap: onTap,
            radius: AppRadius.xs,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(icon, size: 20,
                  semanticLabel: tooltip,
                  color: onTap == null ? scheme.onSurfaceVariant.withValues(alpha: 0.4) : scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

/// A Category or Income Source chip in the Add sheet picker: a white card,
/// or the brand gradient when chosen (Monex "Health" / "Grocery").
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
    final dark = isDarkOf(context);
    return DecoratedBox(
      decoration: selected
          ? gradientDecoration(context, radius: AppRadius.lg)
          : panelDecoration(context, radius: AppRadius.lg),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CategoryIconHelper.getIcon(icon),
                  size: 18,
                  color: selected ? Colors.white : (dark ? AppColors.darkTextPrimary : AppColors.ink),
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
      ),
    );
  }
}
