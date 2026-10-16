import 'package:flutter/material.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';

/// Settings tab. Currency selection lands here with issue 06; for now the
/// screen shows the active currency so the tab is real, not a dead end.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: const Key('settings-screen'),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xl, AppSpace.gutter, 120),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('Settings', style: AppType.title.copyWith(fontSize: 24, color: scheme.onSurface)),
            ),
            const SizedBox(height: AppSpace.lg),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.payments_outlined, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Currency', style: AppType.rowTitle.copyWith(color: scheme.onSurface)),
                          const SizedBox(height: 2),
                          const Text('Choosing a currency is coming soon', style: AppType.caption),
                        ],
                      ),
                    ),
                    Text(
                      Money.currencyLabel,
                      style: AppType.rowAmount.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
