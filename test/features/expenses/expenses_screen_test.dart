import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/categories/cubit/category_cubit.dart';
import 'package:budget_app/features/expenses/cubit/expense_cubit.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
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

  testWidgets('renders empty state when there are no expenses', (tester) async {
    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('renders logged expenses grouped with category and amount', (tester) async {
    final now = DateTime.now();
    await expenseCubit.addExpense(
      amountMinor: 1550, // $15.50
      categoryId: 'cat_food',
      spentOn: now,
    );
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('\$15.50'), findsWidgets);
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets('tapping Log Expense opens form sheet and adds an expense', (tester) async {
    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap FAB
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Log Expense'));
    await tester.pumpAndSettle();

    expect(find.descendant(
      of: find.byType(ExpenseFormSheet),
      matching: find.text('Log Expense'),
    ), findsOneWidget);

    // Enter amount
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '42.50');
    await tester.pumpAndSettle();

    // Tap 'Transport' category chip
    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();

    // Tap Save Expense button
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    // Verify expense appears on screen
    expect(find.text('\$42.50'), findsWidgets);
    expect(find.text('Transport'), findsOneWidget);
  });
}
