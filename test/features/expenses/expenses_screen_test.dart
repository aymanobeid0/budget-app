import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/theme/theme_cubit.dart';
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
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
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

  testWidgets('renders the blue summary card and the transaction row', (tester) async {
    final now = DateTime.now();
    await expenseCubit.addExpense(
      amountMinor: 1550, // 15.50
      categoryId: 'cat_food',
      spentOn: now,
    );
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('month-summary-card')), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('−15.50'), findsOneWidget); // red expense amount
    expect(find.text('Food'), findsOneWidget);
    expect(find.byType(CategoryIconTile), findsOneWidget);
  });

  testWidgets('add flow: amount, pick a category, save', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-first-expense')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text('Add Expense')), findsWidgets);
    expect(find.byKey(const Key('week-strip')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('expense-amount-field')), '42.50');
    await tester.tap(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text('Transport')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    expect(find.text('−42.50'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
  });

  testWidgets('saving without an amount shows an error and stays open', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-first-expense')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount greater than 0'), findsOneWidget);
    expect(find.byType(ExpenseFormSheet), findsOneWidget);
  });

  testWidgets('picking yesterday in the week strip saves it on that date', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-first-expense')));
    await tester.pumpAndSettle();
    final y = DateTime.now().subtract(const Duration(days: 1));
    if (DateTime.now().weekday == DateTime.monday) {
      await tester.tap(find.byTooltip('Previous week'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(Key('day-${y.year}-${y.month}-${y.day}')));
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '1250');
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    expect(find.text('−1,250'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
  });
}
