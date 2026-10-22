import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/month/chosen_month_cubit.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:budget_app/features/income/income.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester,
      {DateTime Function()? clock, Future<void> Function(ExpenseLedger, IncomeLedger)? seed}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final chosenMonth = ChosenMonthCubit(clock: clock);
    addTearDown(chosenMonth.close);
    final expenseLedger = ExpenseLedger(db);
    final incomeLedger = IncomeLedger(db);
    final categoryStore = CategoryStore(db);
    if (seed != null) {
      // Seeds the preset Categories and Income Sources the entries point at.
      await categoryStore.loadCategories();
      await incomeLedger.loadSources();
      await seed(expenseLedger, incomeLedger);
    }
    await tester.pumpWidget(BudgetApp(
      categoryStore: categoryStore,
      expenseLedger: expenseLedger,
      incomeLedger: incomeLedger,
      chosenMonthCubit: chosenMonth,
    ));
    await tester.pumpAndSettle();
  }

  Finder inCard(Finder f) => find.descendant(of: find.byKey(const Key('net-card')), matching: f);

  /// Logs from the Expenses or Income page's + button, then returns to Home.
  Future<void> log(WidgetTester tester, EntryKind kind, String amount, String pick) async {
    final income = kind == EntryKind.income;
    await tester.tap(find.byKey(Key(income ? 'nav-income' : 'nav-expenses')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(income ? 'add-income-btn' : 'add-expense-btn')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount-field')), amount);
    await tester.tap(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text(pick)));
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
  }

  testWidgets('Home shows this month\'s Net and updates it as Income and Expenses change', (tester) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('net-card')), findsOneWidget);
    expect(inCard(find.textContaining('Net in ')), findsOneWidget);

    await log(tester, EntryKind.expense, '300', 'Food');
    expect(inCard(find.textContaining('−300')), findsOneWidget);
    expect(find.byKey(const Key('net-negative')), findsOneWidget);
    // A sign, not a grade: Net is in ink, not Outflow Red, and has no "Behind" arrow.
    final netText = tester.widget<Text>(find.byKey(const Key('net-negative')));
    expect(netText.style!.color, Theme.of(tester.element(find.byKey(const Key('net-card')))).colorScheme.onSurface);
    expect(inCard(find.byIcon(Icons.trending_down_rounded)), findsNothing);

    await log(tester, EntryKind.income, '1000', 'Salary');
    expect(inCard(find.textContaining('+700')), findsOneWidget);
    expect(find.byKey(const Key('net-positive')), findsOneWidget);
  });

  group('the chosen month', () {
    DateTime today() => DateTime(2026, 10, 18, 9, 30);
    final stamp = DateTime.utc(2026, 1, 1);

    Future<void> seed(ExpenseLedger expenses, IncomeLedger income) async {
      Expense expense(String id, int minor, DateTime spentOn, {bool deleted = false}) => Expense(
            id: id, amountMinor: minor, categoryId: 'cat_food', spentOn: spentOn,
            createdAt: stamp, updatedAt: stamp, deletedAt: deleted ? stamp : null);
      Income paid(String id, int minor, DateTime paidOn) => Income(
            id: id, amountMinor: minor, sourceId: 'src_salary', paidOn: paidOn, createdAt: stamp, updatedAt: stamp);
      await expenses.logExpense(expense('exp_oct', 30000, DateTime.utc(2026, 10, 5)));
      await expenses.logExpense(expense('exp_sep', 12500, DateTime.utc(2026, 9, 30)));
      await expenses.logExpense(expense('exp_sep_gone', 99900, DateTime.utc(2026, 9, 3), deleted: true));
      await income.logIncome(paid('inc_oct', 50000, DateTime.utc(2026, 10, 1)));
      await income.logIncome(paid('inc_sep', 20000, DateTime.utc(2026, 9, 1)));
      await income.logIncome(paid('inc_aug', 70000, DateTime.utc(2026, 8, 31)));
    }

    testWidgets('on a past month the card shows that month\'s Net', (tester) async {
      await pumpApp(tester, clock: today, seed: seed);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      // September: 200 Income − 125 Expenses; the deleted Expense never counts.
      expect(inCard(find.text('Net in September')), findsOneWidget);
      expect(inCard(find.textContaining('+75')), findsOneWidget);
      expect(inCard(find.textContaining('Income 200')), findsOneWidget);
      expect(inCard(find.textContaining('Expenses 125')), findsOneWidget);
    });

    testWidgets('on the current month the card shows this month\'s Net, with no period switch', (tester) async {
      await pumpApp(tester, clock: today, seed: seed);

      // October: 500 Income − 300 Expenses; September and August don't count.
      expect(inCard(find.text('Net in October')), findsOneWidget);
      expect(inCard(find.textContaining('+200')), findsOneWidget);
      expect(find.byType(SegmentedButton), findsNothing);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(inCard(find.textContaining('+200')), findsOneWidget);
    });
  });
}
