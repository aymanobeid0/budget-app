import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/money.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../../../core/theme/widgets.dart';
import '../../account/ui/account_section.dart';

/// Profile & settings: avatar header, account actions and preferences as
/// one menu list.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  SyncEngine? _syncEngine(BuildContext context) {
    try {
      return RepositoryProvider.of<SyncEngine>(context);
    } catch (_) {
      return null; // local-only build
    }
  }

  Future<void> _syncNow(BuildContext context, SyncEngine engine) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Syncing…'), duration: Duration(seconds: 1)));
    final result = await engine.sync();
    messenger.showSnackBar(SnackBar(
      content: Text(result.isSuccess ? 'Up to date' : "Couldn't sync. Check your connection."),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.watch<ThemeCubit>().isDark;
    final engine = _syncEngine(context);

    return Scaffold(
      key: const Key('settings-screen'),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 130),
          children: [
            const ScreenHeader(title: 'Profile', trailing: ThemeToggleButton()),
            const SizedBox(height: 18),
            const AccountProfileHeader(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const AccountSection(),
                  MenuRow(
                    key: const Key('profile-categories-row'),
                    icon: Icons.grid_view_rounded,
                    color: scheme.primary,
                    title: 'Categories',
                    subtitle: 'Add, rename or remove expense categories',
                    trailing: const Chevron(),
                    onTap: () => context.go('/settings/categories'),
                  ),
                  MenuRow(
                    icon: Icons.dark_mode_rounded,
                    color: const Color(0xFF1F2A44),
                    title: 'Dark mode',
                    subtitle: isDark ? 'On' : 'Off · light is the default',
                    trailing: Switch(
                      key: const Key('dark-mode-switch'),
                      value: isDark,
                      onChanged: (on) =>
                          context.read<ThemeCubit>().setMode(on ? ThemeMode.dark : ThemeMode.light),
                    ),
                  ),
                  MenuRow(
                    icon: Icons.payments_rounded,
                    color: CategoryPalette.utilities,
                    title: 'Currency',
                    subtitle: 'Choosing a currency is coming soon',
                    trailing: Text(
                      Money.currencyLabel,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                    ),
                    showDivider: engine != null,
                  ),
                  if (engine != null)
                    MenuRow(
                      key: const Key('sync-now-btn'),
                      icon: Icons.sync_rounded,
                      color: CategoryPalette.transport,
                      title: 'Sync now',
                      subtitle: 'Upload and download your changes',
                      trailing: const Chevron(),
                      showDivider: false,
                      onTap: () => _syncNow(context, engine),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
