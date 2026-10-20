import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/theme/empty_state.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:budget_app/features/income/cubit/income_cubit.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  testWidgets('the Income tab with no Income shows the shared empty state, and its action opens the Add sheet on Income', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();

    final empty = find.byType(EmptyState);
    expect(find.descendant(of: empty, matching: find.text('No Income yet')), findsOneWidget);
    await tester.tap(find.descendant(of: empty, matching: find.byKey(const Key('add-first-income'))));
    await tester.pumpAndSettle();

    expect(inSheet(find.text('Income Source')), findsOneWidget);
    expect(find.byKey(const Key('entry-kind-switch')), findsNothing); // Income only
  });

  testWidgets("the Income tab's add button opens Add Income with no Expense option", (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-income-btn')));
    await tester.pumpAndSettle();

    expect(inSheet(find.text('Add Income')), findsWidgets); // title and save button
    expect(inSheet(find.text('Income Source')), findsOneWidget);
    expect(find.byKey(const Key('entry-kind-switch')), findsNothing);
    expect(inSheet(find.text('Food')), findsNothing);
  });

  testWidgets('each add button does one job: Income adds Income, Expenses adds Expenses', (tester) async {
    await incomeLedger.loadSources();
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add expense'), findsNothing); // the Income page only adds Income

    // Log an Income from the Income tab.
    await tester.tap(find.byKey(const Key('add-income-btn')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '900');
    await tester.tap(inSheet(find.text('Salary')));
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    // The Expenses page's + still opens Add Expense.
    await tester.tap(find.byKey(const Key('nav-expenses')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add income'), findsNothing);
    await tester.tap(find.byKey(const Key('add-expense-btn')));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Add Expense')), findsWidgets);
    expect(inSheet(find.text('Category')), findsOneWidget);
  });

  testWidgets('Add Income logs an Income from a picked source', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-income-btn')));
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

    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-income-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount greater than 0'), findsOneWidget);
    expect(find.text('Pick an Income Source'), findsOneWidget);
    expect(find.byType(ExpenseFormSheet), findsOneWidget);
    expect(await incomeLedger.loadIncome(), isEmpty);
  });

  testWidgets('Add Expense opens on Expense even right after adding Income', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-income-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-expenses')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-expense-btn')));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Category')), findsOneWidget);
  });

  testWidgets('tapping an Income edits it, and it can be deleted', (tester) async {
    await incomeLedger.loadSources();
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-income-btn')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '200');
    await tester.tap(inSheet(find.text('Freelance')));
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('income-total')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('income-total')), matching: find.textContaining('200')),
        findsOneWidget);

    await tester.tap(find.text('Freelance'));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Edit Income')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '250');
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();
    expect(find.text('+250'), findsOneWidget);
    expect((await incomeLedger.loadIncome()).single.amountMinor, 25000);

    await tester.tap(find.text('Freelance'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-expense-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(await incomeLedger.loadIncome(), isEmpty);
    expect(find.text('No Income yet'), findsOneWidget);
  });

  testWidgets('the Income Source picker follows source changes while the sheet is open', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-income-btn')));
    await tester.pumpAndSettle();

    final cubit = tester.element(find.byType(ExpenseFormSheet)).read<IncomeCubit>();
    await tester.runAsync(() => cubit.addSource(name: 'Dental clinic', icon: 'work', color: 0xFF0F766E));
    await tester.pumpAndSettle();

    expect(inSheet(find.text('Dental clinic')), findsOneWidget);
  });

  testWidgets('editing Income from a deleted source still shows that source picked', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-income-btn')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '75');
    await tester.tap(inSheet(find.text('Freelance')));
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    final cubit = tester.element(find.byType(MaterialApp).first).read<IncomeCubit>();
    await tester.runAsync(() => cubit.deleteSource('src_freelance'));
    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Freelance'));
    await tester.pumpAndSettle();

    expect(inSheet(find.text('Freelance')), findsOneWidget);
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();
    expect((await incomeLedger.loadIncome()).single.sourceId, 'src_freelance');
  });
}
