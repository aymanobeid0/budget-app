import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/month/chosen_month_cubit.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:budget_app/features/income/cubit/net_period_cubit.dart';
import 'package:budget_app/features/income/income.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:budget_app/features/income/net.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
    AddSheetMemory.reset();
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, NetPeriodStorage storage,
      {DateTime Function()? clock, Future<void> Function(ExpenseLedger, IncomeLedger)? seed}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final cubit = NetPeriodCubit(storage: storage, initial: await storage.read() ?? NetPeriod.month);
    addTearDown(cubit.close);
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
      netPeriodCubit: cubit,
      chosenMonthCubit: chosenMonth,
    ));
    await tester.pumpAndSettle();
  }

  Finder inCard(Finder f) => find.descendant(of: find.byKey(const Key('net-card')), matching: f);

  Future<void> log(WidgetTester tester, EntryKind kind, String amount, String pick) async {
    await tester.tap(find.byKey(const Key('add-expense-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('entry-kind-${kind.name}')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount-field')), amount);
    await tester.tap(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text(pick)));
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();
  }

  testWidgets('Home shows this month\'s Net and updates it as Income and Expenses change', (tester) async {
    await pumpApp(tester, NetPeriodStorage.inMemory());

    expect(find.byKey(const Key('net-card')), findsOneWidget);
    expect(inCard(find.text('This month')), findsOneWidget);

    await log(tester, EntryKind.expense, '300', 'Food');
    expect(inCard(find.textContaining('−300')), findsOneWidget);
    expect(find.byKey(const Key('net-negative')), findsOneWidget);

    await log(tester, EntryKind.income, '1000', 'Salary');
    expect(inCard(find.textContaining('+700')), findsOneWidget);
    expect(find.byKey(const Key('net-positive')), findsOneWidget);
  });

  testWidgets('the last picked period is remembered on the device', (tester) async {
    final storage = NetPeriodStorage.inMemory();
    await pumpApp(tester, storage);

    await tester.tap(find.byKey(const Key('net-period-week')));
    await tester.pumpAndSettle();
    expect(await storage.read(), NetPeriod.week);

    await tester.tap(find.byKey(const Key('net-period-allTime')));
    await tester.pumpAndSettle();
    expect(await storage.read(), NetPeriod.allTime);
    expect(inCard(find.text('All time')), findsWidgets);
  });

  group('on a past month', () {
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

    SegmentedButton<NetPeriod> periodSwitch(WidgetTester tester) =>
        tester.widget<SegmentedButton<NetPeriod>>(find.byType(SegmentedButton<NetPeriod>));

    testWidgets('the card shows that month\'s Net and hides the switch', (tester) async {
      final storage = NetPeriodStorage.inMemory();
      await storage.write(NetPeriod.allTime);
      await pumpApp(tester, storage, clock: today, seed: seed);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      // September: 200 Income − 125 Expenses; the deleted Expense never counts.
      expect(find.byType(SegmentedButton<NetPeriod>), findsNothing);
      expect(inCard(find.text('Net in September')), findsOneWidget);
      expect(inCard(find.textContaining('+75')), findsOneWidget);
      expect(inCard(find.textContaining('Income 200')), findsOneWidget);
      expect(inCard(find.textContaining('Expenses 125')), findsOneWidget);
      expect(await storage.read(), NetPeriod.allTime);
    });

    testWidgets('back on the current month the switch and stored period return', (tester) async {
      final storage = NetPeriodStorage.inMemory();
      await storage.write(NetPeriod.allTime);
      await pumpApp(tester, storage, clock: today, seed: seed);

      // All time: 1,400 Income − 425 Expenses.
      expect(inCard(find.text('Net')), findsOneWidget);
      expect(periodSwitch(tester).selected, {NetPeriod.allTime});
      expect(inCard(find.textContaining('+975')), findsOneWidget);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();

      expect(periodSwitch(tester).selected, {NetPeriod.allTime});
      expect(inCard(find.textContaining('+975')), findsOneWidget);
    });
  });
}
