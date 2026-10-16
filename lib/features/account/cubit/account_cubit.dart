import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../account_service.dart';
import '../data/auth_gateway.dart';

enum AccountStatus {
  /// Supabase isn't configured: the app is local-only.
  unavailable,

  /// Using the app without an account (anonymous Supabase user).
  guest,

  /// Signed into a username/password account.
  signedIn,
}

class AccountState extends Equatable {
  const AccountState({
    required this.status,
    this.username,
    this.recentUsernames = const [],
    this.busy = false,
    this.notice,
  });

  final AccountStatus status;
  final String? username;
  final List<String> recentUsernames;
  final bool busy;

  /// One-off message after a flow (e.g. "uploaded later" warnings).
  final String? notice;

  AccountState copyWith({
    AccountStatus? status,
    String? username,
    bool clearUsername = false,
    List<String>? recentUsernames,
    bool? busy,
    String? notice,
    bool clearNotice = false,
  }) {
    return AccountState(
      status: status ?? this.status,
      username: clearUsername ? null : (username ?? this.username),
      recentUsernames: recentUsernames ?? this.recentUsernames,
      busy: busy ?? this.busy,
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props => [status, username, recentUsernames, busy, notice];
}

class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._service, {this.onDataReplaced})
      : super(const AccountState(status: AccountStatus.unavailable)) {
    _refresh();
  }

  /// Null when Supabase isn't configured.
  final AccountService? _service;

  /// Called after the data on this phone was replaced, so the expense and
  /// category lists reload.
  final Future<void> Function()? onDataReplaced;

  void _refresh({String? notice}) {
    final s = _service;
    if (s == null || isClosed) return;
    final username = s.currentUsername;
    emit(AccountState(
      status: username == null ? AccountStatus.guest : AccountStatus.signedIn,
      username: username,
      recentUsernames: s.recentUsernames,
      notice: notice,
    ));
  }

  /// Resumes an interrupted download after a sign-in (call on app start).
  Future<void> resume() async {
    final s = _service;
    if (s == null) return;
    if (await s.resumeInitialPullIfNeeded()) await onDataReplaced?.call();
  }

  Future<int> localExpenseCount() async => await _service?.localExpenseCount() ?? 0;

  /// Returns null on success, or an error message for the form.
  Future<String?> createAccount(String username, String password) =>
      _run(() => _service!.createAccount(username: username, password: password));

  Future<String?> signIn(String username, String password) =>
      _run(() => _service!.signIn(username: username, password: password));

  Future<String?> signOut() => _run(() => _service!.signOut());

  void clearNotice() {
    if (state.notice != null) emit(state.copyWith(clearNotice: true));
  }

  Future<String?> _run(Future<String?> Function() flow) async {
    if (_service == null) return 'Cloud sync is not set up in this build.';
    if (state.busy) return null;
    emit(state.copyWith(busy: true, clearNotice: true));
    try {
      final warning = await flow();
      await onDataReplaced?.call();
      _refresh(notice: warning);
      return null;
    } on AccountException catch (e) {
      _refresh();
      return e.message;
    }
  }
}
