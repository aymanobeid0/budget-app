import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late CategoryStore categoryStore;
  late ExpenseLedger ledger;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    categoryStore = CategoryStore(db);
    await categoryStore.loadCategories(); // Seeds default categories
    ledger = ExpenseLedger(db);
  });

  tearDown(() => db.close());

  test('logs an expense and retrieves it in reverse-chronological order', () async {
    final exp1 = Expense(
      id: 'exp_1',
      amountMinor: 1550, // $15.50
      categoryId: 'cat_food',
      spentOn: DateTime.utc(2026, 10, 10),
      createdAt: DateTime.utc(2026, 10, 10, 12, 0),
      updatedAt: DateTime.utc(2026, 10, 10, 12, 0),
    );
    final exp2 = Expense(
      id: 'exp_2',
      amountMinor: 4200, // $42.00
      categoryId: 'cat_transport',
      spentOn: DateTime.utc(2026, 10, 12),
      createdAt: DateTime.utc(2026, 10, 12, 9, 30),
      updatedAt: DateTime.utc(2026, 10, 12, 9, 30),
    );

    await ledger.logExpense(exp1);
    await ledger.logExpense(exp2);

    final expenses = await ledger.loadExpenses();
    expect(expenses.length, 2);
    // Reverse-chronological: exp2 (Oct 12) before exp1 (Oct 10)
    expect(expenses.first.id, 'exp_2');
    expect(expenses.first.amountMinor, 4200);
    expect(expenses.last.id, 'exp_1');
    expect(expenses.last.amountMinor, 1550);
  });

  test('updates an existing expense', () async {
    final exp = Expense(
      id: 'exp_update',
      amountMinor: 2000,
      categoryId: 'cat_food',
      spentOn: DateTime.utc(2026, 10, 13),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ledger.logExpense(exp);

    final updated = exp.copyWith(
      amountMinor: 2500,
      categoryId: 'cat_entertainment',
    );
    await ledger.updateExpense(updated);

    final expenses = await ledger.loadExpenses();
    final retrieved = expenses.firstWhere((e) => e.id == 'exp_update');
    expect(retrieved.amountMinor, 2500);
    expect(retrieved.categoryId, 'cat_entertainment');
  });

  test('soft-deletes an expense and excludes it from loadExpenses', () async {
    final exp = Expense(
      id: 'exp_del',
      amountMinor: 999,
      categoryId: 'cat_shopping',
      spentOn: DateTime.utc(2026, 10, 13),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ledger.logExpense(exp);
    expect((await ledger.loadExpenses()).length, 1);

    await ledger.deleteExpense('exp_del');
    expect((await ledger.loadExpenses()).length, 0);
  });

  test('watchExpenses streams new state on write', () async {
    final stream = ledger.watchExpenses();
    expectLater(
      stream,
      emitsInOrder([
        isEmpty, // initial before add
        hasLength(1), // after add
      ]),
    );

    await pumpEventQueue();
    await ledger.logExpense(Expense(
      id: 'exp_stream',
      amountMinor: 500,
      categoryId: 'cat_food',
      spentOn: DateTime.utc(2026, 10, 13),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });
}
