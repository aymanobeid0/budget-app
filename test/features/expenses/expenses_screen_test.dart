import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/month/chosen_month_cubit.dart';
import 'package:budget_app/core/theme/empty_state.dart';
import 'package:budget_app/core/theme/theme_cubit.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/categories/cubit/category_cubit.dart';
import 'package:budget_app/features/expenses/cubit/expense_cubit.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/categories/ui/category_icon_helper.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:budget_app/features/expenses/ui/expenses_screen.dart';
import 'package:budget_app/features/settings/cubit/currency_cubit.dart';
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

  Widget buildTestWidget({DateTime Function()? clock}) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<CategoryCubit>.value(value: categoryCubit),
          BlocProvider<ExpenseCubit>.value(value: expenseCubit),
          BlocProvider<ChosenMonthCubit>(create: (_) => ChosenMonthCubit(clock: clock)),
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<CurrencyCubit>(create: (_) => CurrencyCubit()),
        ],
        child: const ExpensesScreen(),
      ),
    );
  }

  testWidgets('Home with no Expenses shows the shared empty state, and its action opens the Add sheet', (tester) async {
    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final empty = find.byType(EmptyState);
    expect(find.descendant(of: empty, matching: find.text('No Expenses yet')), findsOneWidget);
    await tester.tap(find.descendant(of: empty, matching: find.byKey(const Key('add-first-expense'))));
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseFormSheet), findsOneWidget);
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

  group('stepping between months', () {
    // Sunday 18 October 2026.
    DateTime today() => DateTime(2026, 10, 18, 9, 30);
    Finder inCard(Finder f) => find.descendant(of: find.byKey(const Key('month-summary-card')), matching: f);
    Finder monthLabel(String text) =>
        find.descendant(of: find.byKey(const Key('month-header')), matching: find.text(text));

    String total(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('month-total'))).textSpan!.toPlainText();

    Future<void> pumpHome(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(buildTestWidget(clock: today));
      await tester.pumpAndSettle();
    }

    IconButton arrow(WidgetTester tester, String tooltip) =>
        tester.widget<IconButton>(find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)));

    testWidgets('step back a month and see only that month\'s total and Expenses', (tester) async {
      await expenseCubit.addExpense(amountMinor: 30000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 10, 18));
      await expenseCubit.addExpense(amountMinor: 12500, categoryId: 'cat_transport', spentOn: DateTime.utc(2026, 9, 30));
      await expenseCubit.addExpense(amountMinor: 4000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 9, 2));
      await pumpHome(tester);

      // Opens on the current month, with today and this week on the card.
      expect(monthLabel('October'), findsOneWidget);
      expect(inCard(find.text('Spent in October')), findsOneWidget);
      expect(total(tester), '300  MRU');
      expect(inCard(find.text('Today')), findsOneWidget);
      expect(find.text('−300'), findsOneWidget);
      expect(find.text('−125'), findsNothing);
      expect(arrow(tester, 'Next month').onPressed, isNull);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      expect(monthLabel('September'), findsOneWidget);
      expect(inCard(find.text('Spent in September')), findsOneWidget);
      expect(total(tester), '165  MRU');
      expect(inCard(find.text('Today')), findsNothing);
      expect(inCard(find.text('This week')), findsNothing);
      expect(find.text('−125'), findsOneWidget);
      expect(find.text('−40'), findsOneWidget);
      expect(find.text('−300'), findsNothing);

      // September holds the first entry: no further back.
      expect(arrow(tester, 'Previous month').onPressed, isNull);
      expect(arrow(tester, 'Next month').onPressed, isNotNull);
    });

    testWidgets('a month with no Expenses shows its own empty state', (tester) async {
      await expenseCubit.addExpense(amountMinor: 30000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 10, 1));
      await expenseCubit.addExpense(amountMinor: 4000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 8, 20));
      await pumpHome(tester);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      expect(monthLabel('September'), findsOneWidget);
      expect(total(tester), '0  MRU');
      expect(find.text('No Expenses in September'), findsOneWidget);
      expect(find.text('−300'), findsNothing);
      expect(find.text('−40'), findsNothing);
    });

    testWidgets('swiping the card changes month, and tapping a past month\'s label comes back', (tester) async {
      await expenseCubit.addExpense(amountMinor: 30000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 10, 1));
      await expenseCubit.addExpense(amountMinor: 4000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 8, 20));
      await pumpHome(tester);

      // Swiping left on the current month goes nowhere: no future months.
      await tester.fling(find.byKey(const Key('month-summary-card')), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(monthLabel('October'), findsOneWidget);

      await tester.fling(find.byKey(const Key('month-summary-card')), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(monthLabel('September'), findsOneWidget);

      await tester.fling(find.byKey(const Key('month-header')), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(monthLabel('August'), findsOneWidget);
      expect(find.text('−40'), findsOneWidget);

      await tester.fling(find.byKey(const Key('month-summary-card')), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(monthLabel('September'), findsOneWidget);

      await tester.tap(monthLabel('September'));
      await tester.pumpAndSettle();
      expect(monthLabel('October'), findsOneWidget);
      expect(find.text('−300'), findsOneWidget);
    });

    testWidgets('the card compares the chosen month with the month before', (tester) async {
      await expenseCubit.addExpense(amountMinor: 250000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 10, 2));
      await expenseCubit.addExpense(amountMinor: 170000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 9, 10));
      await expenseCubit.addExpense(amountMinor: 200000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 8, 10));
      await pumpHome(tester);

      // The current month so far against the whole of September.
      expect(inCard(find.text('800 MRU more than September')), findsOneWidget);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(inCard(find.text('300 MRU less than August')), findsOneWidget);

      // August's month before has no Expenses: no comparison.
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(monthLabel('August'), findsOneWidget);
      expect(find.byKey(const Key('month-comparison')), findsNothing);
    });

    testWidgets('with no entries both arrows are disabled', (tester) async {
      await expenseCubit.load();
      await pumpHome(tester);

      expect(monthLabel('October'), findsOneWidget);
      expect(arrow(tester, 'Previous month').onPressed, isNull);
      expect(arrow(tester, 'Next month').onPressed, isNull);
      expect(find.text('No Expenses yet'), findsOneWidget);
    });
  });
}
