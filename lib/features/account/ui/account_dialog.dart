import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../account_service.dart';
import '../cubit/account_cubit.dart';

enum AccountSheetMode { create, signIn }

Future<void> showAccountSheet(BuildContext context, AccountSheetMode mode) {
  final cubit = context.read<AccountCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(value: cubit, child: AccountSheet(initialMode: mode)),
  );
}

/// Create-account / sign-in form. The same sheet handles switching accounts:
/// signing into another account while signed in switches to it.
class AccountSheet extends StatefulWidget {
  const AccountSheet({super.key, required this.initialMode});
  final AccountSheetMode initialMode;

  @override
  State<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<AccountSheet> {
  late AccountSheetMode _mode = widget.initialMode;
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPassword = false;
  String? _error;
  String? _usernameError;
  String? _passwordError;
  String? _confirmError;
  int _guestExpenses = 0;
  int _guestIncome = 0;

  bool get _isCreate => _mode == AccountSheetMode.create;

  /// "3 expenses and 1 income": what a sign-in would replace.
  String _guestEntries() => [
        if (_guestExpenses > 0) '$_guestExpenses ${_guestExpenses == 1 ? 'expense' : 'expenses'}',
        if (_guestIncome > 0) '$_guestIncome income',
      ].join(' and ');

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AccountCubit>();
    if (cubit.state.status == AccountStatus.guest) {
      cubit.localExpenseCount().then((n) {
        if (mounted) setState(() => _guestExpenses = n);
      });
      cubit.localIncomeCount().then((n) {
        if (mounted) setState(() => _guestIncome = n);
      });
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<AccountCubit>();
    setState(() {
      _error = null;
      _usernameError = AccountService.validateUsername(_username.text);
      _passwordError = AccountService.validatePassword(_password.text);
      _confirmError = _isCreate && _confirm.text != _password.text ? "Passwords don't match" : null;
    });
    if (_usernameError != null || _passwordError != null || _confirmError != null) return;

    final error = _isCreate
        ? await cubit.createAccount(_username.text, _password.text)
        : await cubit.signIn(_username.text, _password.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<AccountCubit>().state;
    final signedInAs = state.status == AccountStatus.signedIn ? state.username : null;

    final title = _isCreate
        ? 'Create account'
        : (signedInAs != null ? 'Switch account' : 'Sign in');
    final subtitle = _isCreate
        ? (signedInAs != null
            ? 'Start a new, empty account. $signedInAs stays safe on your server.'
            : 'Your expenses on this phone move into the new account.')
        : (signedInAs != null
            ? 'Signed in as $signedInAs. Enter the account you want to switch to.'
            : 'Sign in to bring back your expenses from your server.');

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        boxShadow: AppShadows.sheet,
      ),
      padding: EdgeInsets.only(
        left: AppSpace.xl,
        right: AppSpace.xl,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.xxl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.handle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(child: Text(title, style: AppType.title.copyWith(color: scheme.onSurface))),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            Text(subtitle, style: TextStyle(fontSize: 14, height: 1.4, color: scheme.onSurfaceVariant)),
            const SizedBox(height: AppSpace.lg),

            if (!_isCreate && signedInAs == null && (_guestExpenses > 0 || _guestIncome > 0)) ...[
              _Callout(
                key: const Key('guest-data-warning'),
                icon: Icons.warning_amber_rounded,
                color: AppColors.expense,
                background: isDark ? const Color(0xFF3A1F1C) : AppColors.expenseContainer,
                text: '${_guestEntries()} on this phone '
                    "aren't in an account and will be replaced. To keep them, create an account instead.",
              ),
              const SizedBox(height: AppSpace.lg),
            ],

            if (!_isCreate && state.recentUsernames.where((u) => u != signedInAs).isNotEmpty) ...[
              Text('Recent on this phone', style: AppType.section.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final u in state.recentUsernames.where((u) => u != signedInAs))
                    ActionChip(
                      key: Key('recent-$u'),
                      avatar: const Icon(Icons.person_outline_rounded, size: 18),
                      label: Text(u),
                      onPressed: () => setState(() => _username.text = u),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
            ],

            TextField(
              key: const Key('account-username-field'),
              controller: _username,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                errorText: _usernameError,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            TextField(
              key: const Key('account-password-field'),
              controller: _password,
              obscureText: !_showPassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: _isCreate ? TextInputAction.next : TextInputAction.done,
              autofillHints: [_isCreate ? AutofillHints.newPassword : AutofillHints.password],
              onSubmitted: _isCreate ? null : (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: _isCreate ? 'At least 6 characters' : null,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                errorText: _passwordError,
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Hide password' : 'Show password',
                  icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            if (_isCreate) ...[
              const SizedBox(height: AppSpace.md),
              TextField(
                key: const Key('account-confirm-field'),
                controller: _confirm,
                obscureText: !_showPassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Repeat password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  errorText: _confirmError,
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: AppSpace.md),
              _Callout(
                key: const Key('account-error'),
                icon: Icons.error_outline_rounded,
                color: AppColors.expense,
                background: isDark ? const Color(0xFF3A1F1C) : AppColors.expenseContainer,
                text: _error!,
              ),
            ],

            const SizedBox(height: AppSpace.xl),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: state.busy ? null : AppShadows.fab,
              ),
              child: FilledButton(
                key: const Key('account-submit-btn'),
                onPressed: state.busy ? null : _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: state.busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(_isCreate ? 'Create account' : (signedInAs != null ? 'Switch' : 'Sign in')),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            TextButton(
              key: const Key('account-mode-toggle'),
              onPressed: state.busy
                  ? null
                  : () => setState(() {
                        _mode = _isCreate ? AccountSheetMode.signIn : AccountSheetMode.create;
                        _error = null;
                        _confirmError = null;
                      }),
              child: Text(_isCreate ? 'I already have an account' : 'Create a new account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final Color background;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, height: 1.4, color: color))),
        ],
      ),
    );
  }
}
