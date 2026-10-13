import 'package:flutter/material.dart';

import '../../../core/theme/empty_state.dart';

/// Placeholder until ticket 03 (Expense logging).
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('expenses-screen'),
      appBar: AppBar(title: const Text('Expenses')),
      body: const EmptyState(
        icon: Icons.receipt_long,
        title: 'No expenses yet',
        message: 'Log your first expense in seconds.',
      ),
    );
  }
}
