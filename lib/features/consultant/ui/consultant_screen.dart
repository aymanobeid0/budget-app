import 'package:flutter/material.dart';

import '../../../core/theme/empty_state.dart';

/// Placeholder until ticket 05 (Expense Consultant chat).
class ConsultantScreen extends StatelessWidget {
  const ConsultantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('consultant-screen'),
      appBar: AppBar(title: const Text('Expense Consultant')),
      body: const EmptyState(
        icon: Icons.auto_awesome,
        title: 'Ask about your spending',
        message: 'Your AI Expense Consultant is coming soon.',
      ),
    );
  }
}
