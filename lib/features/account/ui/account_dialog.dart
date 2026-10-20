import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../account_service.dart';
import '../cubit/account_cubit.dart';

enum AccountDialogMode { create, signIn }

/// Opens centred, above the nav bar; it moves up when the keyboard opens.
Future<void> showAccountDialog(BuildContext context, AccountDialogMode mode) {
  final cubit = context.read<AccountCubit>();
  return showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(value: cubit, child: AccountDialog(initialMode: mode)),
  );
}

/// Create-account / sign-in form. The same dialog handles switching accounts:
/// signing into another account while signed in switches to it.
class AccountDialog extends StatefulWidget {
  const AccountDialog({super.key, required this.initialMode});
  final AccountDialogMode initialMode;

  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  late AccountDialogMode _mode = widget.initialMode;
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

  bool get _isCreate => _mode == AccountDialogMode.create;

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

    return Dialog(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: AppSpace.xl),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.md, AppSpace.xl, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: AppSpace.xl),
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
              const SizedBox(height: AppSpace.xl),
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

            const SizedBox(height: AppSpace.xxl),
            FilledButton(
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
            const SizedBox(height: AppSpace.md),
            // Only the link word is tappable; the question before it is plain text.
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _isCreate
                      ? 'Already have an account? '
                      : (signedInAs != null ? 'Need another account? ' : "Don't have an account? "),
                  style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                ),
                // A plain link: no button background, splash or highlight.
                Semantics(
                  link: true,
                  child: GestureDetector(
                    key: const Key('account-mode-toggle'),
                    behavior: HitTestBehavior.opaque,
                    onTap: state.busy
                        ? null
                        : () => setState(() {
                              _mode = _isCreate ? AccountDialogMode.signIn : AccountDialogMode.create;
                              _error = null;
                              _confirmError = null;
                            }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: 10),
                      child: Text(
                        _isCreate ? 'Sign in' : 'Sign up',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: state.busy ? scheme.onSurfaceVariant : scheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: state.busy ? scheme.onSurfaceVariant : scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
