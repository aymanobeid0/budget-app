import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/widgets.dart';
import '../cubit/account_cubit.dart';
import 'account_dialog.dart';

/// Avatar, name and status at the top of the Profile screen.
class AccountProfileHeader extends StatelessWidget {
  const AccountProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<AccountCubit>().state;
    final signedIn = state.status == AccountStatus.signedIn;
    final name = signedIn ? (state.username ?? '') : (state.status == AccountStatus.guest ? 'Guest' : 'This phone');
    final subtitle = switch (state.status) {
      AccountStatus.signedIn => 'Signed in · synced to your server',
      AccountStatus.guest => 'Not linked to an account',
      AccountStatus.unavailable => 'Cloud backup is off',
    };

    return Column(
      key: Key(signedIn ? 'account-signed-in-row' : 'account-guest-row'),
      children: [
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: signedIn ? scheme.primary : scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: signedIn
                    ? Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: Colors.white),
                      )
                    : Icon(Icons.person_rounded, size: 52, color: scheme.onPrimaryContainer),
              ),
              if (signedIn)
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.raised,
                    ),
                    child: state.busy
                        ? const Padding(padding: EdgeInsets.all(7), child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_rounded, size: 17, color: AppColors.income),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(name, style: AppType.title.copyWith(fontSize: 20, color: scheme.onSurface)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Account actions as menu rows: create / sign in for guests; switch and
/// sign out when signed in.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  Future<void> _confirmSignOut(BuildContext context, String username) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          "Your data stays safe in $username's account. This phone will be cleared "
          "and you'll continue as a guest.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
              minimumSize: const Size(88, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error = await context.read<AccountCubit>().signOut();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<AccountCubit, AccountState>(
      listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.notice!)));
        context.read<AccountCubit>().clearNotice();
      },
      builder: (context, state) {
        final rows = <Widget>[];
        switch (state.status) {
          case AccountStatus.unavailable:
            rows.add(const MenuRow(
              icon: Icons.cloud_off_rounded,
              color: AppColors.chevron,
              title: 'Accounts unavailable',
              subtitle: 'Add your Supabase keys to .env to enable accounts.',
            ));
          case AccountStatus.guest:
            rows
              ..add(MenuRow(
                key: const Key('create-account-btn'),
                icon: Icons.person_add_alt_1_rounded,
                color: scheme.primary,
                title: 'Create account',
                subtitle: 'Keep your data after a reinstall',
                trailing: const Chevron(),
                onTap: state.busy ? null : () => showAccountDialog(context, AccountDialogMode.create),
              ))
              ..add(MenuRow(
                key: const Key('sign-in-btn'),
                icon: Icons.login_rounded,
                color: CategoryPalette.transport,
                title: 'Sign in',
                subtitle: 'Bring back an existing account',
                trailing: const Chevron(),
                onTap: state.busy ? null : () => showAccountDialog(context, AccountDialogMode.signIn),
              ));
          case AccountStatus.signedIn:
            rows
              ..add(MenuRow(
                key: const Key('switch-account-btn'),
                icon: Icons.swap_horiz_rounded,
                color: scheme.primary,
                title: 'Switch account',
                trailing: const Chevron(),
                onTap: state.busy ? null : () => showAccountDialog(context, AccountDialogMode.signIn),
              ))
              ..add(MenuRow(
                key: const Key('sign-out-btn'),
                icon: Icons.logout_rounded,
                color: AppColors.danger,
                title: 'Sign out',
                destructive: true,
                trailing: const Chevron(),
                onTap: state.busy ? null : () => _confirmSignOut(context, state.username ?? ''),
              ));
        }
        return Column(key: const Key('account-section'), children: rows);
      },
    );
  }
}
