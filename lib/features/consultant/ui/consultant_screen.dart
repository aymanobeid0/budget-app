import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/empty_state.dart';

/// Placeholder until ticket 05 (Expense Consultant chat).
class ConsultantScreen extends StatelessWidget {
  const ConsultantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: const Key('consultant-screen'),
      appBar: AppBar(
        title: const Text('Expense Consultant'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
              ),
              child: Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
      body: const EmptyState(
        icon: Icons.auto_awesome_rounded,
        title: 'Ask about your spending',
        message: 'Your AI Expense Consultant is coming soon.',
      ),
    );
  }
}
