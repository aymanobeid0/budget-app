import 'dart:async';

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'cloud_sync_client.dart';
import 'sync_status.dart';

/// Deep module orchestrating local SQLite and remote Supabase synchronization.
///
/// Ensures offline-first continuity: local mutations succeed immediately,
/// while cloud synchronization runs in the background.
class SyncEngine {
  SyncEngine({
    required this.db,
    required this.client,
  });

  final AppDatabase db;
  final CloudSyncClient client;

  final _statusController = StreamController<SyncState>.broadcast();
  SyncState _currentState = SyncState.idle;

  SyncState get currentState => _currentState;
  Stream<SyncState> get statusStream => _statusController.stream;

  void _setState(SyncState state) {
    _currentState = state;
    _statusController.add(state);
  }

  Future<SyncResult>? _inFlight;

  /// While true, background syncs are skipped. Account switching sets this
  /// so a stray sync can't push one account's rows into another account or
  /// sign in anonymously halfway through a switch.
  bool paused = false;

  /// Executes full two-way synchronization: pushes unsynced local changes,
  /// then pulls remote changes. Concurrent calls share one run.
  ///
  /// [force] runs even while [paused] (used by the account flow itself).
  Future<SyncResult> sync({bool force = false}) async {
    if (paused && !force) return SyncResult.failure('Sync paused');
    if (force) {
      // A run that started before the caller changed accounts may still be
      // using the old session: let it finish, then start a fresh run.
      await idle();
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
        return SyncResult.failure('Authentication required for sync');
      }

      final syncTimestamp = DateTime.now().millisecondsSinceEpoch;

      // 1. Push unsynced categories
      final unsyncedCategories = await db.raw.query(
        'categories',
        where: 'synced_at IS NULL OR updated_at > synced_at',
      );

      if (unsyncedCategories.isNotEmpty) {
        debugPrint('🔄 [SyncEngine] Pushing ${unsyncedCategories.length} categories to Supabase...');
        final remoteCategories = unsyncedCategories.map((c) {
          final createdAtMs = c['created_at'] as int;
          final updatedAtMs = c['updated_at'] as int;
          final deletedAtMs = c['deleted_at'] as int?;

          return {
            'id': c['id'],
            'user_id': userId,
            'name': c['name'],
            'icon': c['icon'],
            'color': c['color'],
            'created_at': DateTime.fromMillisecondsSinceEpoch(createdAtMs, isUtc: true).toIso8601String(),
            'updated_at': DateTime.fromMillisecondsSinceEpoch(updatedAtMs, isUtc: true).toIso8601String(),
            'deleted_at': deletedAtMs != null
                ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs, isUtc: true).toIso8601String()
                : null,
          };
        }).toList();

        await client.upsertCategories(remoteCategories);
        debugPrint('✅ [SyncEngine] Successfully synced ${remoteCategories.length} categories.');

        // Mark local categories as synced
        final categoryIds = unsyncedCategories.map((c) => c['id'] as String).toList();
        final placeholders = List.filled(categoryIds.length, '?').join(',');
        await db.raw.rawUpdate(
          'UPDATE categories SET synced_at = ? WHERE id IN ($placeholders)',
          [syncTimestamp, ...categoryIds],
        );
      }

      // 2. Push unsynced expenses
      final unsyncedExpenses = await db.raw.query(
        'expenses',
        where: 'synced_at IS NULL OR updated_at > synced_at',
      );

      if (unsyncedExpenses.isNotEmpty) {
        debugPrint('🔄 [SyncEngine] Pushing ${unsyncedExpenses.length} expenses to Supabase...');
        final remoteExpenses = unsyncedExpenses.map((e) {
          final createdAtMs = e['created_at'] as int;
          final updatedAtMs = e['updated_at'] as int;
          final deletedAtMs = e['deleted_at'] as int?;

          return {
            'id': e['id'],
            'user_id': userId,
            'amount_minor': e['amount_minor'],
            'category_id': e['category_id'],
            'spent_on': e['spent_on'],
            'created_at': DateTime.fromMillisecondsSinceEpoch(createdAtMs, isUtc: true).toIso8601String(),
            'updated_at': DateTime.fromMillisecondsSinceEpoch(updatedAtMs, isUtc: true).toIso8601String(),
            'deleted_at': deletedAtMs != null
                ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs, isUtc: true).toIso8601String()
                : null,
          };
        }).toList();

        await client.upsertExpenses(remoteExpenses);
        debugPrint('✅ [SyncEngine] Successfully synced ${remoteExpenses.length} expenses.');

        // Mark local expenses as synced
        final expenseIds = unsyncedExpenses.map((e) => e['id'] as String).toList();
        final placeholders = List.filled(expenseIds.length, '?').join(',');
        await db.raw.rawUpdate(
          'UPDATE expenses SET synced_at = ? WHERE id IN ($placeholders)',
          [syncTimestamp, ...expenseIds],
        );
      }

      // 3. Pull remote categories
      final remoteCategories = await client.fetchCategories();
      for (final r in remoteCategories) {
        final id = r['id'] as String;
        final name = r['name'] as String;
        final icon = r['icon'] as String;
        final color = r['color'] as int;
        final createdAtMs = DateTime.parse(r['created_at'] as String).millisecondsSinceEpoch;
        final updatedAtMs = DateTime.parse(r['updated_at'] as String).millisecondsSinceEpoch;
        final deletedAtMs = r['deleted_at'] != null
            ? DateTime.parse(r['deleted_at'] as String).millisecondsSinceEpoch
            : null;

        final existing = await db.raw.query('categories', where: 'id = ?', whereArgs: [id]);
        if (existing.isEmpty) {
          await db.raw.insert('categories', {
            'id': id,
            'name': name,
            'icon': icon,
            'color': color,
            'created_at': createdAtMs,
            'updated_at': updatedAtMs,
            'deleted_at': deletedAtMs,
            'synced_at': syncTimestamp,
          });
        } else {
          final localUpdatedAt = existing.first['updated_at'] as int;
          if (updatedAtMs >= localUpdatedAt) {
            await db.raw.update(
              'categories',
              {
                'name': name,
                'icon': icon,
                'color': color,
                'created_at': createdAtMs,
                'updated_at': updatedAtMs,
                'deleted_at': deletedAtMs,
                'synced_at': syncTimestamp,
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }
      }

      // 4. Pull remote expenses
      final remoteExpenses = await client.fetchExpenses();
      for (final r in remoteExpenses) {
        final id = r['id'] as String;
        final amountMinor = r['amount_minor'] as int;
        final categoryId = r['category_id'] as String;
        final spentOn = r['spent_on'] as String;
        final createdAtMs = DateTime.parse(r['created_at'] as String).millisecondsSinceEpoch;
        final updatedAtMs = DateTime.parse(r['updated_at'] as String).millisecondsSinceEpoch;
        final deletedAtMs = r['deleted_at'] != null
            ? DateTime.parse(r['deleted_at'] as String).millisecondsSinceEpoch
            : null;

        final existing = await db.raw.query('expenses', where: 'id = ?', whereArgs: [id]);
        if (existing.isEmpty) {
          await db.raw.insert('expenses', {
            'id': id,
            'amount_minor': amountMinor,
            'category_id': categoryId,
            'spent_on': spentOn,
            'created_at': createdAtMs,
            'updated_at': updatedAtMs,
            'deleted_at': deletedAtMs,
            'synced_at': syncTimestamp,
          });
        } else {
          final localUpdatedAt = existing.first['updated_at'] as int;
          if (updatedAtMs >= localUpdatedAt) {
            await db.raw.update(
              'expenses',
              {
                'amount_minor': amountMinor,
                'category_id': categoryId,
                'spent_on': spentOn,
                'created_at': createdAtMs,
                'updated_at': updatedAtMs,
                'deleted_at': deletedAtMs,
                'synced_at': syncTimestamp,
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }
      }

      _setState(SyncState.success);
      return SyncResult.success(
        categories: unsyncedCategories.length + remoteCategories.length,
        expenses: unsyncedExpenses.length + remoteExpenses.length,
      );
    } catch (e, st) {
      debugPrint('SyncEngine error: $e\n$st');
      _setState(SyncState.error);
      return SyncResult.failure(e.toString());
    }
  }

  void dispose() {
    _statusController.close();
  }
}
