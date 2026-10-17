import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/widgets.dart';
import '../../categories/ui/category_icon_helper.dart';
import '../../expenses/ui/expense_form_sheet.dart';
import '../cubit/income_cubit.dart';
import '../cubit/income_state.dart';
import '../income.dart';
import '../income_source.dart';

const _shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Income tab: the Income list, newest first and grouped by day.
class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const header = ScreenHeader(title: 'Income');

    return Scaffold(
      key: const Key('income-screen'),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<IncomeCubit, IncomeState>(
          builder: (context, state) {
            if (state is IncomeError) {
              return Column(
                children: [
                  header,
                  Expanded(
                    child: Center(
                      child: Text('Error: ${state.message}', style: TextStyle(color: scheme.error)),
                    ),
                  ),
                ],
              );
            }
            if (state is! IncomeLoaded) {
              return const Column(
                children: [
                  header,
                  Expanded(child: Center(child: CircularProgressIndicator())),
                ],
              );
            }

            final sources = {for (final s in state.sources) s.id: s};
            final days = state.groupedByDay;
            final dayTotals = state.dayTotals;
            return ListView(
              padding: const EdgeInsets.only(bottom: 130),
              children: [
                header,
                if (days.isEmpty)
                  _EmptyIncome(onAdd: () => showExpenseSheet(context, kind: EntryKind.income))
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 22, AppSpace.gutter, 0),
                    child: _TotalCard(totalMinor: state.totalMinor),
                  ),
                  for (final day in days.entries) ...[
                    _DayHeader(day: day.value.first.paidOn, totalMinor: dayTotals[day.key]!),
                    for (final i in day.value)
                      _IncomeRow(
                        income: i,
                        source: sources[i.sourceId],
                        onTap: () => showExpenseSheet(context, income: i),
                      ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Total of everything listed on the tab.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.totalMinor});
  final int totalMinor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('income-total'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: raisedDecoration(context, radius: AppRadius.xl, shadow: AppShadows.panel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total income',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(Money.withLabel(totalMinor), style: AppType.heroAmount.copyWith(color: AppColors.income)),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.totalMinor});
  final DateTime day;
  final int totalMinor;

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final label = '${_weekdays[d.weekday - 1]}, ${d.day} ${_shortMonths[d.month - 1]}';
    return d.year == now.year ? label : '$label ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 22, AppSpace.gutter, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(_label(), style: AppType.caption.copyWith(color: scheme.onSurfaceVariant)),
          ),
          Text(
            Money.withLabel(totalMinor),
            style: AppType.caption.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppFonts.tabular),
          ),
        ],
      ),
    );
  }
}

class _IncomeRow extends StatelessWidget {
  const _IncomeRow({required this.income, required this.source, required this.onTap});

  final Income income;
  final IncomeSource? source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = source != null ? Color(source!.color) : AppColors.income;
    final icon = source != null ? CategoryIconHelper.getIcon(source!.icon) : Icons.payments_rounded;

    return InkWell(
      key: ValueKey('income-${income.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: 10),
        child: Row(
          children: [
            CategoryIconTile(icon: icon, color: color, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Text(source?.name ?? 'Unknown source', style: AppType.rowTitle.copyWith(color: scheme.onSurface)),
            ),
            Text('+${Money.format(income.amountMinor)}', style: AppType.rowAmount.copyWith(color: AppColors.income)),
          ],
        ),
      ),
    );
  }
}

class _EmptyIncome extends StatelessWidget {
  const _EmptyIncome({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 40, AppSpace.gutter, 0),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
            child: Icon(Icons.payments_rounded, size: 32, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text('No income yet', style: AppType.title.copyWith(color: scheme.onSurface)),
          const SizedBox(height: 6),
          Text(
            'Tap + and switch to Income to log money you were paid.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.45, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('add-first-income'),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Log your first income'),
          ),
        ],
      ),
    );
  }
}
