import 'package:flutter/material.dart';

import '../format/money.dart';
import '../theme/app_theme.dart';
import 'breakdown.dart';

/// A month's total per group (Category on Home, Income Source on the Income
/// tab), largest first, as a bottom sheet. Tapping a row closes the sheet
/// and returns that group's id; dismissing it returns null.
///
/// [title] names the month, e.g. "Spent in October".
Future<String?> showBreakdownSheet(
  BuildContext context, {
  required String title,
  required int totalMinor,
  required List<BreakdownRow> rows,
  required Currency currency,
  String emptyMessage = 'Nothing logged this month.',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true, // as tall as the list, scrolling on short screens
    useSafeArea: true,
    useRootNavigator: true, // above the nav bar
    builder: (sheetContext) => BreakdownSheet(
      title: title,
      totalMinor: totalMinor,
      rows: rows,
      currency: currency,
      emptyMessage: emptyMessage,
      onSelect: (id) => Navigator.of(sheetContext).pop(id),
    ),
  );
}

/// The body of [showBreakdownSheet].
class BreakdownSheet extends StatelessWidget {
  const BreakdownSheet({
    super.key,
    required this.title,
    required this.totalMinor,
    required this.rows,
    required this.currency,
    required this.onSelect,
    this.emptyMessage = 'Nothing logged this month.',
  });

  final String title;
  final int totalMinor;
  final List<BreakdownRow> rows;
  final Currency currency;
  final ValueChanged<String> onSelect;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      key: const Key('breakdown-sheet'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 20, AppSpace.gutter, 2),
            child: Text(title, style: AppType.title.copyWith(color: scheme.onSurface)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, 8),
            child: Text(
              Money.withLabel(totalMinor, currency),
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant, fontFeatures: AppFonts.tabular),
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 12, AppSpace.gutter, 12),
              child: Text(emptyMessage, style: AppType.caption.copyWith(color: scheme.onSurfaceVariant)),
            ),
          for (final row in rows)
            _BreakdownRowTile(
              key: Key('breakdown-row-${row.group.id}'),
              row: row,
              currency: currency,
              onTap: () => onSelect(row.group.id),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// "60%"; a share too small to round up shows as "<1%".
String _shareLabel(double share) {
  final percent = (share * 100).round();
  return percent == 0 && share > 0 ? '<1%' : '$percent%';
}

class _BreakdownRowTile extends StatelessWidget {
  const _BreakdownRowTile({super.key, required this.row, required this.currency, required this.onTap});

  final BreakdownRow row;
  final Currency currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: 10),
        child: Row(
          children: [
            GroupIconTile(group: row.group, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.group.name, style: AppType.rowTitle.copyWith(color: scheme.onSurface)),
                  const SizedBox(height: 3),
                  Text(_shareLabel(row.share), style: AppType.caption.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Text(
              Money.withLabel(row.totalMinor, currency),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                fontFeatures: AppFonts.tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A group's icon on a tint of its colour, as Category rows show it.
class GroupIconTile extends StatelessWidget {
  const GroupIconTile({super.key, required this.group, this.size = 40});

  final BreakdownGroup group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? group.color.withValues(alpha: 0.2) : CategoryPalette.tint(group.color),
        borderRadius: BorderRadius.circular(size >= 40 ? AppRadius.lg : AppRadius.xs),
      ),
      child: Icon(group.icon, size: size * 0.48, color: isDark ? group.color : CategoryPalette.onTint(group.color)),
    );
  }
}

/// Names the group a list is filtered to, with an × that clears it.
class GroupFilterChip extends StatelessWidget {
  const GroupFilterChip({super.key, required this.group, required this.onClear});

  final BreakdownGroup group;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InputChip(
        key: const Key('group-filter-chip'),
        avatar: Icon(group.icon, size: 18, color: group.color),
        label: Text(group.name),
        deleteIcon: const Icon(Icons.close_rounded, size: 18),
        deleteButtonTooltipMessage: 'Clear filter',
        onDeleted: onClear,
        onPressed: onClear,
      ),
    );
  }
}
