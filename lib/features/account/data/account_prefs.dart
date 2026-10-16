import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Small on-device record for the account flow. Never holds passwords.
class AccountPrefs {
  const AccountPrefs({this.recentUsernames = const [], this.awaitingInitialPull = false});

  /// Usernames used on this device, most recent first (for quick switching).
  final List<String> recentUsernames;

  /// True after the local data was cleared for a sign-in but the account's
  /// data hasn't been downloaded yet. Default categories are not re-seeded
  /// meanwhile, so they can't overwrite the account's own categories.
  final bool awaitingInitialPull;

  AccountPrefs copyWith({List<String>? recentUsernames, bool? awaitingInitialPull}) => AccountPrefs(
        recentUsernames: recentUsernames ?? this.recentUsernames,
        awaitingInitialPull: awaitingInitialPull ?? this.awaitingInitialPull,
      );

  Map<String, dynamic> toJson() => {
        'recentUsernames': recentUsernames,
        'awaitingInitialPull': awaitingInitialPull,
      };

  factory AccountPrefs.fromJson(Map<String, dynamic> json) => AccountPrefs(
        recentUsernames: (json['recentUsernames'] as List?)?.cast<String>() ?? const [],
        awaitingInitialPull: json['awaitingInitialPull'] as bool? ?? false,
      );
}

abstract class AccountPrefsStorage {
  Future<AccountPrefs> read();
  Future<void> write(AccountPrefs prefs);
}

class InMemoryAccountPrefsStorage implements AccountPrefsStorage {
  AccountPrefs _prefs = const AccountPrefs();

  @override
  Future<AccountPrefs> read() async => _prefs;

  @override
  Future<void> write(AccountPrefs prefs) async => _prefs = prefs;
}

class FileAccountPrefsStorage implements AccountPrefsStorage {
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'account_prefs.json'));
  }

  @override
  Future<AccountPrefs> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const AccountPrefs();
      return AccountPrefs.fromJson(jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    } catch (_) {
      return const AccountPrefs();
    }
  }

  @override
  Future<void> write(AccountPrefs prefs) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(prefs.toJson()));
    } catch (_) {
      // Best effort: losing the recent-usernames list is harmless.
    }
  }
}
