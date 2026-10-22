import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/money.dart';
import '../../../core/month/chosen_month_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/widgets.dart';
import '../../expenses/cubit/expense_cubit.dart';
import '../../expenses/cubit/expense_state.dart';
import '../../expenses/expense.dart';
import '../../settings/cubit/currency_cubit.dart';
import '../cubit/income_cubit.dart';
import '../cubit/income_state.dart';
import '../income.dart';
import '../net.dart';

/// Home's Net (Income minus Expenses) for the chosen month, the same month
/// the Spent card above it shows. Rebuilds whenever either ledger or the
/// chosen month changes.
class NetCard extends StatelessWidget {
  const NetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chosen = context.watch<ChosenMonthCubit>();
    final month = chosen.state;
    final currency = context.watch<CurrencyCubit>().state;
    final expenseState = context.watch<ExpenseCubit>().state;
    final incomeState = context.watch<IncomeCubit>().state;

    final income = incomeState is IncomeLoaded ? incomeState.income : const <Income>[];
    final expenses = expenseState is ExpenseLoaded ? expenseState.expenses : const <Expense>[];
    final net = calculateNetForMonth(income: income, expenses: expenses, month: month);
    final sign = net.netMinor > 0 ? '+' : (net.isNegative ? '−' : '');

    return Container(
      key: const Key('net-card'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Net in ${month.label(today: chosen.today)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            // Ink, whichever way it goes: red and green belong to Expenses
            // and Income, and Net is neither (DESIGN.md, the Money Hues rule).
            child: Text(
              '$sign${Money.withLabel(net.netMinor.abs(), currency)}',
              key: Key(net.isNegative ? 'net-negative' : 'net-positive'),
              style: AppType.entryAmount.copyWith(color: scheme.onSurface),
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
