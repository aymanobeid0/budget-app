import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/database/app_database.dart';
import '../../core/sync/sync_engine.dart';
import 'data/account_prefs.dart';
import 'data/auth_gateway.dart';

/// Deep module for accounts: username + password on top of Supabase Auth.
///
/// Usernames are mapped to an internal email (`name@budgetapp.local`) because
/// Supabase Auth signs in by email. The server must auto-confirm sign-ups
/// (GOTRUE_MAILER_AUTOCONFIRM=true), which the bundled Docker stack does.
///
/// Rules:
/// * Guest = anonymous Supabase user. Data still syncs, but can't be
///   recovered after a reinstall.
/// * Creating an account moves everything on this phone into it.
/// * Signing in (or switching) uploads the current account's pending changes,
///   then replaces the data on this phone with the new account's data.
/// * Signing out uploads pending changes, clears the phone and starts a
///   fresh guest session.
class AccountService {
  AccountService({
    required this._db,
    required this._auth,
    required this._syncEngine,
    AccountPrefsStorage? prefsStorage,
  }) : _prefsStorage = prefsStorage ?? InMemoryAccountPrefsStorage();

  static const emailDomain = 'budgetapp.local';
  static const _maxRecent = 5;

  final AppDatabase _db;
  final AuthGateway _auth;
  final SyncEngine _syncEngine;
  final AccountPrefsStorage _prefsStorage;

  AccountPrefs _prefs = const AccountPrefs();

  // ── Validation ────────────────────────────────────────────────────────

  static final _usernamePattern = RegExp(r'^[a-z0-9._-]{3,24}$');

  static String normalize(String username) => username.trim().toLowerCase();

  /// Returns an error message, or null when valid.
  static String? validateUsername(String raw) {
    final u = normalize(raw);
    if (u.isEmpty) return 'Enter a username';
    if (u.length < 3) return 'At least 3 characters';
    if (u.length > 24) return 'At most 24 characters';
    if (!_usernamePattern.hasMatch(u)) return 'Use letters, numbers, dots, dashes or underscores';
    return null;
  }

  static String? validatePassword(String password) {
    if (password.length < 6) return 'At least 6 characters';
    return null;
  }

  static String emailFor(String username) => '${normalize(username)}@$emailDomain';

  static String? usernameFromEmail(String? email) {
    if (email == null) return null;
    final suffix = '@$emailDomain';
    return email.endsWith(suffix) ? email.substring(0, email.length - suffix.length) : email;
  }

  // ── State ─────────────────────────────────────────────────────────────

  /// Username of the signed-in account, or null when using the app as a guest.
  String? get currentUsername => usernameFromEmail(_auth.accountEmail);

  List<String> get recentUsernames => _prefs.recentUsernames;

  bool get awaitingInitialPull => _prefs.awaitingInitialPull;

  /// Guard for [CategoryStore] and the Income Ledger: don't seed defaults
  /// while an account's own categories and Income Sources are still waiting
  /// to be downloaded.
  bool canSeedDefaults() => !_prefs.awaitingInitialPull;

  Future<void> init() async {
    _prefs = await _prefsStorage.read();
  }

  Future<int> localExpenseCount() async {
    final rows = await _db.raw.rawQuery('SELECT COUNT(*) AS n FROM expenses WHERE deleted_at IS NULL');
    return (rows.first['n'] as int?) ?? 0;
  }

  // ── Flows ─────────────────────────────────────────────────────────────

  /// Creates an account and moves this phone's data into it.
  /// Returns a warning when the account exists but the upload didn't finish.
  Future<String?> createAccount({required String username, required String password}) {
    return _guarded(() async {
      _check(username, password);
      if (currentUsername != null) {
        // Already in an account: back it up, then start the new one empty.
        await _uploadPendingBeforeLeaving();
        await _auth.signUp(email: emailFor(username), password: password);
        await _wipeLocal();
        await _setAwaitingInitialPull(false);
        await _remember(username);
        return null;
      }
      await _auth.signUp(email: emailFor(username), password: password);
      await _markAllUnsynced(); // re-upload everything under the new account
      final result = await _syncEngine.sync(force: true);
      await _remember(username);
      return result.isSuccess
          ? null
          : 'Account created, but your data hasn\'t uploaded yet. It will retry automatically.';
    });
  }

  /// Signs into an existing account (also used to switch accounts) and
  /// replaces the data on this phone with that account's data.
  Future<String?> signIn({required String username, required String password}) {
    return _guarded(() async {
      _check(username, password);
      if (currentUsername == normalize(username)) {
        throw const AccountException('You are already signed in to this account.');
      }
      await _uploadPendingBeforeLeaving();
      await _auth.signIn(email: emailFor(username), password: password);
      return _replaceLocalWithAccountData(username);
    });
  }

  /// Signs out, clears this phone and continues as a fresh guest.
  Future<String?> signOut() {
    return _guarded(() async {
      await _uploadPendingBeforeLeaving();
      await _auth.signOut();
      await _wipeLocal();
      await _setAwaitingInitialPull(false);
      try {
        await _auth.signInAsGuest();
      } catch (e) {
        // Offline: the next sync starts the guest session.
        debugPrint('ℹ️ Guest session deferred: $e');
      }
      return null;
    });
  }

  /// Finishes a download that failed right after a sign-in (e.g. the app
  /// was closed or went offline). Returns true when data was replaced.
  Future<bool> resumeInitialPullIfNeeded() async {
    if (!_prefs.awaitingInitialPull || currentUsername == null) return false;
    final result = await _syncEngine.sync(force: true);
    if (result.isSuccess) await _setAwaitingInitialPull(false);
    return result.isSuccess;
  }

  // ── Internals ─────────────────────────────────────────────────────────

  Future<String?> _replaceLocalWithAccountData(String username) async {
    await _wipeLocal();
    await _setAwaitingInitialPull(true);
    final result = await _syncEngine.sync(force: true);
    if (result.isSuccess) await _setAwaitingInitialPull(false);
    await _remember(username);
    return result.isSuccess
        ? null
        : 'Signed in, but your data couldn\'t be downloaded yet. It will retry automatically.';
  }

  /// A signed-in account's unsent changes must reach the server before the
  /// phone is cleared. Guest data is the caller's (UI's) responsibility to
  /// confirm, since guests can't be signed back into.
  Future<void> _uploadPendingBeforeLeaving() async {
    if (currentUsername == null) return;
    final result = await _syncEngine.sync(force: true);
    if (!result.isSuccess) {
      throw const AccountException(
        "Couldn't back up this account's latest changes, so nothing was changed. "
        'Check your connection and try again.',
      );
    }
  }

  void _check(String username, String password) {
    final u = validateUsername(username);
    if (u != null) throw AccountException(u);
    final p = validatePassword(password);
    if (p != null) throw AccountException('Password: ${p.toLowerCase()}');
  }

  Future<String?> _guarded(Future<String?> Function() body) async {
    _syncEngine.paused = true;
    try {
      // A background sync that started under the current session must finish
      // before the session or the local rows change underneath it.
      await _syncEngine.idle();
      return await body();
    } on AccountException {
      rethrow;
    } catch (e) {
      debugPrint('Account flow error: $e');
      throw const AccountException("Can't reach the server. Check your connection and try again.");
    } finally {
      _syncEngine.paused = false;
    }
  }

  Future<void> _markAllUnsynced() async {
    await _db.raw.rawUpdate('UPDATE categories SET synced_at = NULL');
    await _db.raw.rawUpdate('UPDATE expenses SET synced_at = NULL');
    await _db.raw.rawUpdate('UPDATE income_sources SET synced_at = NULL');
    await _db.raw.rawUpdate('UPDATE income SET synced_at = NULL');
  }

  Future<void> _wipeLocal() async {
    await _db.raw.transaction((txn) async {
      await txn.delete('expenses');
      await txn.delete('categories');
      await txn.delete('income');
      await txn.delete('income_sources');
    });
  }

  Future<void> _setAwaitingInitialPull(bool value) async {
    _prefs = _prefs.copyWith(awaitingInitialPull: value);
    await _prefsStorage.write(_prefs);
  }

  Future<void> _remember(String username) async {
    final u = normalize(username);
    final list = [u, ..._prefs.recentUsernames.where((e) => e != u)].take(_maxRecent).toList();
    _prefs = _prefs.copyWith(recentUsernames: list);
    await _prefsStorage.write(_prefs);
  }
}
