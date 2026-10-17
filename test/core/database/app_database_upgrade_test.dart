import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'dart:io';

void main() {
  setUpAll(sqfliteFfiInit);

  test('upgrading a version-1 install keeps Expenses and Categories and adds empty income', () async {
    final dir = await Directory.systemTemp.createTemp('budget_upgrade_');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'v1.db');

    // A version-1 database exactly as the first release created it.
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE categories (
              id TEXT PRIMARY KEY, name TEXT NOT NULL, icon TEXT NOT NULL,
              color INTEGER NOT NULL, created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL, deleted_at INTEGER, synced_at INTEGER
            )''');
          await db.execute('''
            CREATE TABLE expenses (
              id TEXT PRIMARY KEY,
              amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
              category_id TEXT NOT NULL REFERENCES categories (id),
              spent_on TEXT NOT NULL, created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL, deleted_at INTEGER, synced_at INTEGER
            )''');
          await db.execute('CREATE INDEX expenses_spent_on_idx ON expenses (spent_on DESC)');
        },
      ),
    );
    await v1.insert('categories', {
      'id': 'cat_rent', 'name': 'Rent', 'icon': 'home', 'color': 1,
      'created_at': 1, 'updated_at': 1,
    });
    await v1.insert('expenses', {
      'id': 'e1', 'amount_minor': 9900, 'category_id': 'cat_rent',
      'spent_on': '2026-10-01', 'created_at': 1, 'updated_at': 1,
    });
    await v1.close();

    final db = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
    addTearDown(db.close);

    final categories = await CategoryStore(db).loadCategories();
    expect(categories.map((c) => c.name), ['Rent']);
    final expenses = await ExpenseLedger(db).loadExpenses();
    expect(expenses.single.amountMinor, 9900);

    final income = IncomeLedger(db);
    expect(await income.loadIncome(), isEmpty);
    expect(await income.loadSources(), hasLength(3)); // income tables exist and seed
  });
}
