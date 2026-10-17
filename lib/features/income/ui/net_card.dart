import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/widgets.dart';
import '../../expenses/cubit/expense_cubit.dart';
import '../../expenses/cubit/expense_state.dart';
import '../../settings/cubit/currency_cubit.dart';
import '../cubit/income_cubit.dart';
import '../cubit/income_state.dart';
import '../cubit/net_period_cubit.dart';
import '../net.dart';

/// Home's Net (Income minus Expenses) with a this week / this month / all
/// time switch. Rebuilds whenever either ledger or the period changes.
class NetCard extends StatelessWidget {
  const NetCard({super.key});

  static const _labels = {
    NetPeriod.week: 'This week',
    NetPeriod.month: 'This month',
    NetPeriod.allTime: 'All time',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final period = context.watch<NetPeriodCubit>().state;
    final currency = context.watch<CurrencyCubit>().state;
    final expenseState = context.watch<ExpenseCubit>().state;
    final incomeState = context.watch<IncomeCubit>().state;

    final net = calculateNet(
      income: incomeState is IncomeLoaded ? incomeState.income : const [],
      expenses: expenseState is ExpenseLoaded ? expenseState.expenses : const [],
      period: period,
      today: DateTime.now(),
    );
    final sign = net.netMinor > 0 ? '+' : (net.isNegative ? '−' : '');
    final color = net.isNegative ? AppColors.expense : AppColors.income;

    return Container(
      key: const Key('net-card'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: raisedDecoration(context, radius: AppRadius.xl, shadow: AppShadows.panel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<NetPeriod>(
            segments: [
              for (final p in NetPeriod.values)
                ButtonSegment(value: p, label: Text(_labels[p]!, key: Key('net-period-${p.name}'))),
            ],
            selected: {period},
            showSelectedIcon: false,
            onSelectionChanged: (s) => context.read<NetPeriodCubit>().select(s.first),
          ),
          const SizedBox(height: 14),
          Text('Net', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              key: Key(net.isNegative ? 'net-negative' : 'net-positive'),
              children: [
                if (net.isNegative) ...[
                  const Icon(Icons.trending_down_rounded, color: AppColors.expense, semanticLabel: 'Behind'),
                  const SizedBox(width: 6),
                ],
                Text(
                  '$sign${Money.withLabel(net.netMinor.abs(), currency)}',
                  style: AppType.heroAmount.copyWith(color: color, fontSize: 30),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Income ${Money.withLabel(net.incomeMinor, currency)} · '
            'Expenses ${Money.withLabel(net.expensesMinor, currency)}',
            style: AppType.caption.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppFonts.tabular),
          ),
        ],
      ),
    );
  }
}
