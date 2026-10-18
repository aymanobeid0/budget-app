import 'dart:async';

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'cloud_sync_client.dart';
import 'sync_status.dart';

/// Starts a one-shot timer. Injected so tests can fire retries by hand.
typedef StartTimer = Timer Function(Duration delay, void Function() callback);

/// Deep module orchestrating local SQLite and remote Supabase synchronization.
///
/// Ensures offline-first continuity: local mutations succeed immediately,
/// while cloud synchronization runs in the background.
class SyncEngine {
  SyncEngine({
    required this.db,
    required this.client,
    this.startTimer = Timer.new,
  });

  final AppDatabase db;
  final CloudSyncClient client;
  final StartTimer startTimer;

  /// Waits between retries after a sync ends offline or in error. The last
  /// one repeats until a sync succeeds.
  static const retryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(minutes: 1),
    Duration(minutes: 5),
  ];

  Timer? _retryTimer;
  int _retryAttempt = 0;

  final _statusController = StreamController<SyncState>.broadcast();
  SyncState _currentState = SyncState.idle;

  SyncState get currentState => _currentState;
  Stream<SyncState> get statusStream => _statusController.stream;

  /// Set by [dispose]. A run still in flight then finishes quietly: no
  /// state events, no retry.
  bool _disposed = false;

  void _setState(SyncState state) {
    if (_disposed) return;
    _currentState = state;
    _statusController.add(state);
  }

  /// A finished run either clears the backoff (success) or schedules the
  /// next retry, replacing any retry already waiting.
  void _afterRun(bool succeeded) {
    _retryTimer?.cancel();
    _retryTimer = null;
    if (_disposed) return;
    if (succeeded) {
      _retryAttempt = 0;
      return;
    }
    _retryAttempt++;
    if (!_paused) _scheduleRetry();
  }

  void _scheduleRetry() {
    final delay = retryDelays[(_retryAttempt - 1).clamp(0, retryDelays.length - 1)];
    _retryTimer = startTimer(delay, () {
      if (!_disposed) unawaited(sync());
    });
  }

  Future<SyncResult>? _inFlight;

  /// While true, background syncs are skipped. Account switching sets this
  /// so a stray sync can't push one account's rows into another account or
  /// sign in anonymously halfway through a switch. No retry timer runs while
  /// paused; a pending retry starts again when the pause ends.
  bool get paused => _paused;
  bool _paused = false;
  set paused(bool value) {
    _paused = value;
    _retryTimer?.cancel();
    _retryTimer = null;
    if (!value && _retryAttempt > 0 && !_disposed) _scheduleRetry();
  }

  /// Executes full two-way synchronization: pushes unsynced local changes,
  /// then pulls remote changes. Concurrent calls share one run.
  ///
  /// [force] runs even while [paused] (used by the account flow itself).
  Future<SyncResult> sync({bool force = false}) async {
    if (_disposed) return SyncResult.failure('Sync stopped');
    if (paused && !force) return SyncResult.failure('Sync paused');
    if (force) {
      // A run that started before the caller changed accounts may still be
      // using the old session: let it finish, then start a fresh run.
      await idle();
      if (_disposed) return SyncResult.failure('Sync stopped');
      return _start();
    }
    return _inFlight ?? _start();
  }

  /// Completes once no sync is running.
  Future<void> idle() async {
    while (_inFlight != null) {
      await _inFlight;
    }
  }

  Future<SyncResult> _start() {
    final run = _run();
    _inFlight = run;
    run.whenComplete(() {
      if (identical(_inFlight, run)) _inFlight = null;
    });
    return run;
  }

  Future<SyncResult> _run() async {
    _setState(SyncState.syncing);

    try {
      final userId = await client.ensureAuthenticated();
      if (userId == null) {
        _setState(SyncState.offline);
        _afterRun(false);
        return SyncResult.failure('Authentication required for sync');
      }

      final syncTimestamp = DateTime.now().millisecondsSinceEpoch;

      // Push in dependency order (a label before what it labels), then pull.
      final pushed = <String, int>{};
      for (final table in _tables) {
        pushed[table.name] = await _push(table, userId, syncTimestamp);
      }
      final pulled = <String, int>{};
      for (final table in _tables) {
        pulled[table.name] = await _pull(table, syncTimestamp);
      }

      _setState(SyncState.success);
      _afterRun(true);
      int synced(String table) => pushed[table]! + pulled[table]!;
      return SyncResult.success(
        categories: synced('categories'),
        expenses: synced('expenses'),
        incomeSources: synced('income_sources'),
        income: synced('income'),
      );
    } catch (e, st) {
      debugPrint('SyncEngine error: $e\n$st');
      _setState(SyncState.error);
      _afterRun(false);
      return SyncResult.failure(e.toString());
    }
  }

  /// Synced tables in dependency order: Income Sources go before Income as
  /// Categories go before Expenses.
  late final List<_SyncedTable> _tables = [
    _SyncedTable('categories', ['name', 'icon', 'color'], client.upsertCategories, client.fetchCategories),
    _SyncedTable('expenses', ['amount_minor', 'category_id', 'spent_on'], client.upsertExpenses, client.fetchExpenses),
    _SyncedTable('income_sources', ['name', 'icon', 'color'], client.upsertIncomeSources, client.fetchIncomeSources),
    _SyncedTable('income', ['amount_minor', 'source_id', 'paid_on'], client.upsertIncome, client.fetchIncome),
  ];

  /// Uploads rows changed since their last sync and marks them synced.
  Future<int> _push(_SyncedTable table, String userId, int syncTimestamp) async {
    final unsynced = await db.raw.query(table.name, where: 'synced_at IS NULL OR updated_at > synced_at');
    if (unsynced.isEmpty) return 0;

    debugPrint('🔄 [SyncEngine] Pushing ${unsynced.length} ${table.name} to Supabase...');
    String iso(Object? ms) => DateTime.fromMillisecondsSinceEpoch(ms as int, isUtc: true).toIso8601String();
    await table.upsert([
      for (final row in unsynced)
        {
          'id': row['id'],
          'user_id': userId,
          for (final c in table.columns) c: row[c],
          'created_at': iso(row['created_at']),
          'updated_at': iso(row['updated_at']),
          'deleted_at': row['deleted_at'] == null ? null : iso(row['deleted_at']),
        },
    ]);
    debugPrint('✅ [SyncEngine] Successfully synced ${unsynced.length} ${table.name}.');

    final ids = unsynced.map((r) => r['id'] as String).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.raw.rawUpdate(
      'UPDATE ${table.name} SET synced_at = ? WHERE id IN ($placeholders)',
      [syncTimestamp, ...ids],
    );
    return unsynced.length;
  }

  /// Downloads the account's rows; the newer `updated_at` wins.
  Future<int> _pull(_SyncedTable table, int syncTimestamp) async {
    final remote = await table.fetch();
    int? ms(Object? iso) => iso == null ? null : DateTime.parse(iso as String).millisecondsSinceEpoch;
    for (final r in remote) {
      final id = r['id'] as String;
      final values = {
        for (final c in table.columns) c: r[c],
        'created_at': ms(r['created_at']),
        'updated_at': ms(r['updated_at']),
        'deleted_at': ms(r['deleted_at']),
        'synced_at': syncTimestamp,
      };

      final existing = await db.raw.query(table.name, columns: ['updated_at'], where: 'id = ?', whereArgs: [id]);
      if (existing.isEmpty) {
        await db.raw.insert(table.name, {'id': id, ...values});
      } else if (values['updated_at']! >= (existing.first['updated_at'] as int)) {
        await db.raw.update(table.name, values, where: 'id = ?', whereArgs: [id]);
      }
    }
    return remote.length;
  }

  /// Stops the engine for good: cancels any waiting retry, and later
  /// [sync] calls (including a timer that already fired) do nothing.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _statusController.close();
  }
}

/// One local table mirrored to the cloud. [columns] are its data columns;
/// id and the created/updated/deleted timestamps are handled for every table.
class _SyncedTable {
  const _SyncedTable(this.name, this.columns, this.upsert, this.fetch);

  final String name;
  final List<String> columns;
  final Future<void> Function(List<Map<String, dynamic>> rows) upsert;
  final Future<List<Map<String, dynamic>>> Function() fetch;
}
