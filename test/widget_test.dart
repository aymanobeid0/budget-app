import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/router/app_shell.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late CategoryStore store;
  late ExpenseLedger ledger;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    store = CategoryStore(db);
    ledger = ExpenseLedger(db);
  });

  tearDown(() => db.close());

  testWidgets('shell shows four tabs plus the add button and starts on Expenses', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    expect(find.byType(CalmNavBar), findsOneWidget);
    for (final label in ['Expenses', 'Categories', 'Consultant', 'Settings']) {
      expect(find.byKey(Key('nav-${label.toLowerCase()}')), findsOneWidget);
    }
    expect(find.byKey(const Key('add-expense-fab')), findsOneWidget);
    expect(find.byKey(const Key('expenses-screen')), findsOneWidget);
  });

  testWidgets('tapping a tab switches the visible screen', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-consultant')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('consultant-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-categories')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('categories-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-screen')), findsOneWidget);
  });

  testWidgets('raised add button in the nav bar opens the expense sheet', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-expense-fab')));
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseFormSheet), findsOneWidget);
    expect(find.text('New expense'), findsOneWidget);
  });
}
