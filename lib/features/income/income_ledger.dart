import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/sync/sync_engine.dart';
import 'income.dart';
import 'income_source.dart';

/// Deep module for Income and Income Sources (ADR 0004, ADR 0006).
///
/// Hides the SQLite tables, preset seeding and change notifications. Every
/// mutation clears the row's synced timestamp and starts a background sync.
class IncomeLedger {
  IncomeLedger(this._db, {this.syncEngine, bool Function()? canSeedDefaults})
      : _canSeedDefaults = canSeedDefaults; // ignore: prefer_initializing_formals

  final AppDatabase _db;
  final SyncEngine? syncEngine;

  /// When this returns false, an empty sources table is left empty instead
  /// of being seeded (an account's own sources are still downloading).
  final bool Function()? _canSeedDefaults;

  final _incomeController = StreamController<List<Income>>.broadcast();

  static final List<IncomeSource> defaultSources = [
    _preset('src_salary', 'Salary', 'work', 0xFF2563EB),
    _preset('src_freelance', 'Freelance', 'savings', 0xFF0F766E),
    _preset('src_other', 'Other', 'receipt', 0xFF7C3AED),
  ];

  static IncomeSource _preset(String id, String name, String icon, int color) => IncomeSource(
        id: id,
        name: name,
        icon: icon,
        color: color,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  /// Active Income, newest paid-on date first.
  Future<List<Income>> loadIncome() async {
    final rows = await _db.raw.query(
      'income',
      where: 'deleted_at IS NULL',
      orderBy: 'paid_on DESC, created_at DESC',
    );
    final income = rows.map(Income.fromMap).toList();
    _incomeController.add(income);
    return income;
  }

  /// Emits the latest Income list after every change.
  Stream<List<Income>> watchIncome() {
    loadIncome();
    return _incomeController.stream;
  }

  Future<void> logIncome(Income income) async {
    await _db.raw.insert(
      'income',
      income.toMap()..['synced_at'] = null,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _changed();
  }

  /// Saves new values for an existing Income.
  Future<void> updateIncome(Income income) async {
    await _db.raw.update(
      'income',
      income.toMap()..['synced_at'] = null,
      where: 'id = ?',
      whereArgs: [income.id],
    );
    await _changed();
  }

  /// Soft-deletes an Income so the deletion can sync.
  Future<void> deleteIncome(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.raw.update(
      'income',
      {'deleted_at': now, 'updated_at': now, 'synced_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _changed();
  }

  /// Income Sources the user can pick, by name. Seeds the presets on an
  /// empty table.
  ///
  /// With [includeDeleted], deleted sources come back too, so past Income
  /// can still show where it came from.
  Future<List<IncomeSource>> loadSources({bool includeDeleted = false}) async {
    final count = await _db.raw.rawQuery('SELECT COUNT(*) AS n FROM income_sources');
    final tableEmpty = ((count.first['n'] as int?) ?? 0) == 0;
    if (tableEmpty && (_canSeedDefaults?.call() ?? true)) await _seedDefaults();

    final rows = await _db.raw.query(
      'income_sources',
      where: includeDeleted ? null : 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );
    return rows.map(IncomeSource.fromMap).toList();
  }

  /// Creates or replaces an Income Source.
  Future<void> saveSource(IncomeSource source) async {
    await _db.raw.insert(
      'income_sources',
      source.toMap()..['synced_at'] = null,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    unawaited(syncEngine?.sync().then((_) {}));
  }

  /// Soft-deletes an Income Source. Its past Income is kept and still counts.
  Future<void> deleteSource(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.raw.update(
      'income_sources',
      {'deleted_at': now, 'updated_at': now, 'synced_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
    unawaited(syncEngine?.sync().then((_) {}));
  }

  Future<void> _seedDefaults() async {
    final batch = _db.raw.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final preset in defaultSources) {
      final map = preset.toMap()
        ..['created_at'] = now
        ..['updated_at'] = now;
      batch.insert('income_sources', map, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    unawaited(syncEngine?.sync().then((_) {}));
  }

  Future<void> _changed() async {
    await loadIncome();
    unawaited(syncEngine?.sync().then((_) {}));
  }

  void dispose() {
    _incomeController.close();
  }
}
