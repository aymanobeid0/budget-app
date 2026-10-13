import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import 'expense.dart';

/// Deep module interface for Expense persistence and local ledger queries.
///
/// Implements ADR 0004: encapsulates all SQLite table operations, index
/// usage, and reactive stream broadcasts.
class ExpenseLedger {
  ExpenseLedger(this._db);

  final AppDatabase _db;
  final _controller = StreamController<List<Expense>>.broadcast();

  /// Loads all active expenses in reverse-chronological order.
  Future<List<Expense>> loadExpenses() async {
    final rows = await _db.raw.query(
      'expenses',
      where: 'deleted_at IS NULL',
      orderBy: 'spent_on DESC, created_at DESC',
    );

    final expenses = rows.map((r) => Expense.fromMap(r)).toList();
    _controller.add(expenses);
    return expenses;
  }

  /// Broadcast stream emitting the latest expenses whenever mutations occur.
  Stream<List<Expense>> watchExpenses() {
    loadExpenses();
    return _controller.stream;
  }

  /// Logs a new expense into local SQLite.
  Future<void> logExpense(Expense expense) async {
    await _db.raw.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadExpenses();
  }

  /// Updates an existing expense in local SQLite.
  Future<void> updateExpense(Expense expense) async {
    await _db.raw.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadExpenses();
  }

  /// Soft-deletes an expense so it can be synced upstream later.
  Future<void> deleteExpense(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.raw.update(
      'expenses',
      {
        'deleted_at': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadExpenses();
  }

  void dispose() {
    _controller.close();
  }
}
