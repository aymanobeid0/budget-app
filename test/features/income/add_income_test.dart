import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late IncomeLedger incomeLedger;
  late ExpenseLedger expenseLedger;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
    incomeLedger = IncomeLedger(db);
    expenseLedger = ExpenseLedger(db);
    AddSheetMemory.reset();
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BudgetApp(
      categoryStore: CategoryStore(db),
      expenseLedger: expenseLedger,
      incomeLedger: incomeLedger,
    ));
    await tester.pumpAndSettle();
  }

  Finder inSheet(Finder f) => find.descendant(of: find.byType(ExpenseFormSheet), matching: f);

  testWidgets('switching the Add sheet to Income logs an Income from a picked source', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('add-expense-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('entry-kind-income')));
    await tester.pumpAndSettle();

    expect(inSheet(find.text('Income Source')), findsOneWidget);
    expect(inSheet(find.text('Food')), findsNothing); // categories are not offered
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '3500');
    await tester.tap(inSheet(find.text('Salary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    final logged = await incomeLedger.loadIncome();
    expect(logged.single.amountMinor, 350000);
    expect(logged.single.sourceId, 'src_salary');
    expect(await expenseLedger.loadExpenses(), isEmpty);

    // It shows on the Income tab.
    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('income-screen')), findsOneWidget);
    expect(find.text('+3,500'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
  });

  testWidgets('Income needs an amount above zero and an Income Source', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('add-expense-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('entry-kind-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount greater than 0'), findsOneWidget);
    expect(find.text('Pick an Income Source'), findsOneWidget);
    expect(find.byType(ExpenseFormSheet), findsOneWidget);
    expect(await incomeLedger.loadIncome(), isEmpty);
  });

  testWidgets('the Add sheet reopens on the mode used last', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('add-expense-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('entry-kind-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-expense-fab')));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Income Source')), findsOneWidget);
  });
}
