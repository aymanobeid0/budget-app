import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:budget_app/features/income/cubit/net_period_cubit.dart';
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

  Future<void> pumpApp(WidgetTester tester, NetPeriodStorage storage) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final cubit = NetPeriodCubit(storage: storage, initial: await storage.read() ?? NetPeriod.month);
    addTearDown(cubit.close);
    await tester.pumpWidget(BudgetApp(
      categoryStore: CategoryStore(db),
      expenseLedger: ExpenseLedger(db),
      incomeLedger: IncomeLedger(db),
      netPeriodCubit: cubit,
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
}
