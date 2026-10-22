import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/widgets.dart';
import '../cubit/ai_provider_cubit.dart';
import '../models/ai_provider.dart';
import 'provider_editor_sheet.dart';

/// The AI Providers the user can connect, each with its masked key and
/// status. Tapping one opens the editor.
class AiProviderScreen extends StatelessWidget {
  const AiProviderScreen({super.key});

  void _openEditor(BuildContext context, AiProviderKind kind) {
    final cubit = context.read<AiProviderCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true, // above the nav bar, so Save is never covered
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(value: cubit, child: ProviderEditorSheet(kind: kind)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();
    final cubit = context.watch<AiProviderCubit>();
    final settings = cubit.state;
    final providers = cubit.providers;

    return Scaffold(
      key: const Key('ai-provider-screen'),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 130),
          children: [
            ScreenHeader(
              title: 'AI provider',
              leading: canPop
                  ? SquareIconButton(
                      icon: Icons.adaptive.arrow_back_rounded,
                      tooltip: 'Back',
                      onTap: () => context.pop(),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 18, AppSpace.gutter, 8),
              child: Text(
                'The Expense Consultant answers with your own API key. Keys stay on this phone.',
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final kind in providers)
                    MenuRow(
                      key: Key('provider-row-${kind.name}'),
                      icon: Icons.auto_awesome,
                      color: scheme.primary,
                      title: kind.displayName,
                      subtitle: _subtitle(settings, kind),
                      trailing: settings.saved[kind] == null
                          ? const Chevron()
                          : KeyStatusChip(provider: settings.saved[kind]!),
                      showDivider: kind != providers.last,
                      onTap: () => _openEditor(context, kind),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _subtitle(AiProviderSettings settings, AiProviderKind kind) {
    final saved = settings.saved[kind];
    if (saved == null) return 'Not connected';
    final active = settings.active == kind ? ' · active' : '';
    return '${saved.maskedKey} · ${saved.model}$active';
  }
}

/// Connected, Not verified, or why the key failed.
class KeyStatusChip extends StatelessWidget {
  const KeyStatusChip({super.key, required this.provider});

  final SavedProvider provider;

  @override
  Widget build(BuildContext context) {
    final color = keyStatusColor(provider.status);
    return Container(
      // A long outcome wraps instead of pushing the row off a phone screen.
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        provider.statusLabel,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

Color keyStatusColor(KeyStatus status) => switch (status) {
      KeyStatus.connected => AppColors.income,
      KeyStatus.notVerified => CategoryPalette.food,
      KeyStatus.failed => AppColors.expense,
    };
