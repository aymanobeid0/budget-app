import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/categories/cubit/category_cubit.dart';
import 'package:budget_app/features/expenses/cubit/expense_cubit.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/categories/ui/category_icon_helper.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:budget_app/features/expenses/ui/expenses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late CategoryStore categoryStore;
  late CategoryCubit categoryCubit;
  late ExpenseLedger ledger;
  late ExpenseCubit expenseCubit;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    categoryStore = CategoryStore(db);
    categoryCubit = CategoryCubit(categoryStore);
    await categoryCubit.load(); // Seed default categories

    ledger = ExpenseLedger(db);
    expenseCubit = ExpenseCubit(ledger);
  });

  tearDown(() async {
    await expenseCubit.close();
    await categoryCubit.close();
    await db.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<CategoryCubit>.value(value: categoryCubit),
          BlocProvider<ExpenseCubit>.value(value: expenseCubit),
        ],
        child: const ExpensesScreen(),
      ),
    );
  }

  testWidgets('renders empty state with an add action when there are no expenses', (tester) async {
    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.byKey(const Key('add-first-expense')), findsOneWidget);
  });

  testWidgets('renders logged expenses grouped with category icon and amount', (tester) async {
    final now = DateTime.now();
    await expenseCubit.addExpense(
      amountMinor: 1550, // 15.50
      categoryId: 'cat_food',
      spentOn: now,
    );
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('month-summary-card')), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('15.50'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.byType(CategoryIconTile), findsOneWidget);
  });

  testWidgets('add flow: keypad amount, pick category, save', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-first-expense')));
    await tester.pumpAndSettle();
    expect(find.descendant(
      of: find.byType(ExpenseFormSheet),
      matching: find.text('New expense'),
    ), findsOneWidget);

    // Type 42.5 on the on-screen keypad.
    for (final k in ['4', '2', '.', '5']) {
      await tester.tap(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text(k)));
      await tester.pump();
    }
    expect(find.text('Save · 42.50 MRU'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text('Transport')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    expect(find.text('42.50'), findsOneWidget);
    expect(find.text('Transport'), findsWidgets);
  });

  testWidgets('typing into the amount field still works (hardware keyboard)', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-first-expense')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '1250');
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    expect(find.text('1,250'), findsOneWidget);
  });
}
