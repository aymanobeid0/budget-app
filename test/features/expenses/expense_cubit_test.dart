import 'package:bloc_test/bloc_test.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/cubit/expense_cubit.dart';
import 'package:budget_app/features/expenses/cubit/expense_state.dart';
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
    await categoryStore.loadCategories();
    ledger = ExpenseLedger(db);
  });

  tearDown(() => db.close());

  blocTest<ExpenseCubit, ExpenseState>(
    'emits [ExpenseLoading, ExpenseLoaded] on load()',
    build: () => ExpenseCubit(ledger),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<ExpenseLoading>(),
      isA<ExpenseLoaded>().having((s) => s.expenses, 'expenses', isEmpty),
    ],
  );

  blocTest<ExpenseCubit, ExpenseState>(
    'adds an expense and calculates total amount correctly',
    build: () => ExpenseCubit(ledger),
    act: (cubit) => cubit.addExpense(
      amountMinor: 2550, // $25.50
      categoryId: 'cat_food',
      spentOn: DateTime.utc(2026, 10, 13),
    ),
    expect: () => [
      isA<ExpenseLoaded>().having(
        (s) => s.totalMinor,
        'totalMinor',
        2550,
      ).having(
        (s) => s.totalAmount,
        'totalAmount',
        25.50,
      ).having(
        (s) => s.expenses.length,
        'length',
        1,
      ),
    ],
  );

  blocTest<ExpenseCubit, ExpenseState>(
    'updates an expense and recalculates totals',
    build: () => ExpenseCubit(ledger),
    act: (cubit) async {
      await cubit.addExpense(
        amountMinor: 1000,
        categoryId: 'cat_food',
        spentOn: DateTime.utc(2026, 10, 13),
      );
      final current = (cubit.state as ExpenseLoaded).expenses.first;
      await cubit.updateExpense(current.copyWith(amountMinor: 1500));
    },
    expect: () => [
      isA<ExpenseLoaded>().having((s) => s.totalMinor, 'totalMinor after add', 1000),
      isA<ExpenseLoaded>().having((s) => s.totalMinor, 'totalMinor after update', 1500),
    ],
  );

  blocTest<ExpenseCubit, ExpenseState>(
    'deletes an expense and updates state',
    build: () => ExpenseCubit(ledger),
    act: (cubit) async {
      await cubit.addExpense(
        amountMinor: 800,
        categoryId: 'cat_transport',
        spentOn: DateTime.utc(2026, 10, 13),
      );
      final current = (cubit.state as ExpenseLoaded).expenses.first;
      await cubit.deleteExpense(current.id);
    },
    expect: () => [
      isA<ExpenseLoaded>().having((s) => s.expenses.length, 'length after add', 1),
      isA<ExpenseLoaded>().having((s) => s.expenses.isEmpty, 'empty after delete', isTrue),
    ],
  );
}
