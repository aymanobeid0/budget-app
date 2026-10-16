import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin seam over Supabase Auth so the account flow can be tested without a
/// server.
abstract class AuthGateway {
  /// Email of the signed-in permanent account, or null for a guest
  /// (anonymous) or signed-out session.
  String? get accountEmail;

  /// Creates a permanent account and signs into it.
  Future<void> signUp({required String email, required String password});

  /// Signs into an existing account.
  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  /// Starts a fresh guest session so local data still has an owner to sync to.
  Future<void> signInAsGuest();
}

/// Raised with a message that can be shown to the user as-is.
class AccountException implements Exception {
  const AccountException(this.message);
  final String message;

  @override
  String toString() => message;
}

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client);

  final SupabaseClient _client;

  @override
  String? get accountEmail {
    final user = _client.auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    return user.email;
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      final res = await _client.auth.signUp(email: email, password: password);
      if (res.session == null) {
        // Server requires email confirmation: usernames can't confirm email.
        throw const AccountException(
          'The server is asking for email confirmation. Turn on auto-confirm '
          '(GOTRUE_MAILER_AUTOCONFIRM=true) in your Supabase settings.',
        );
      }
    } on AuthException catch (e) {
      throw AccountException(_friendly(e));
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AccountException(_friendly(e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException {
      // Already signed out on the server; the local session is cleared anyway.
    }
  }

  @override
  Future<void> signInAsGuest() async {
    try {
      await _client.auth.signInAnonymously();
    } on AuthException catch (e) {
      throw AccountException(_friendly(e));
    }
  }

  static String _friendly(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('already registered') || m.contains('already exists')) {
      return 'That username is taken. Try another one, or sign in instead.';
    }
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return 'Wrong username or password.';
    }
    if (m.contains('password') && (m.contains('short') || m.contains('at least'))) {
      return 'Password must be at least 6 characters.';
    }
    if (m.contains('signups not allowed') || m.contains('signup is disabled')) {
      return 'Sign-ups are turned off on the server.';
    }
    if (m.contains('anonymous') && m.contains('disabled')) {
      return 'Guest mode is turned off on the server.';
    }
    if (m.contains('socket') || m.contains('failed host') || m.contains('network')) {
      return "Can't reach the server. Check your connection and try again.";
    }
    return e.message;
  }
}
