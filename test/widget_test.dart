import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
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

  testWidgets('shell shows three tabs and starts on Expenses', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Expenses'), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Categories'), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Consultant'), findsOneWidget);
    expect(find.byKey(const Key('expenses-screen')), findsOneWidget);
  });

  testWidgets('tapping a tab switches the visible screen', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Consultant'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('consultant-screen')), findsOneWidget);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('categories-screen')), findsOneWidget);
  });
}
