import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/month/chosen_month_cubit.dart';
import 'package:budget_app/core/theme/empty_state.dart';
import 'package:budget_app/core/theme/theme_cubit.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/categories/cubit/category_cubit.dart';
import 'package:budget_app/features/categories/cubit/category_state.dart';
import 'package:budget_app/features/expenses/cubit/expense_cubit.dart';
import 'package:budget_app/features/expenses/cubit/expense_state.dart';
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

  /// What the shell's Add Expense button does; Home alone has no shell.
  Future<void> openAddExpense(WidgetTester tester) async {
    showExpenseSheet(tester.element(find.byType(ExpensesScreen)));
    await tester.pumpAndSettle();
  }

  String monthTotal(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('month-total'))).textSpan!.toPlainText();

  testWidgets('Home with no Expenses shows the shared empty state, pointing at Add Expense', (tester) async {
    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final empty = find.byType(EmptyState);
    expect(find.descendant(of: empty, matching: find.text('No Expenses yet')), findsOneWidget);
    expect(find.descendant(of: empty, matching: find.textContaining('Tap Add Expense')), findsOneWidget);
    // One add action per screen: the empty state has no button of its own.
    expect(find.descendant(of: empty, matching: find.byType(ButtonStyleButton)), findsNothing);
    await openAddExpense(tester);

    expect(find.byType(ExpenseFormSheet), findsOneWidget);
  });

  testWidgets('renders the gradient summary card over the Latest Entries', (tester) async {
    final now = DateTime.now();
    await expenseCubit.addExpense(
      amountMinor: 1550, // 15.50
      categoryId: 'cat_food',
      spentOn: now,
    );
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('month-summary-card')), findsOneWidget);
    expect(monthTotal(tester), '15.50  MRU');
    expect(find.text('Latest Entries'), findsOneWidget);
    expect(find.text('- 15.50'), findsOneWidget);
    expect(find.byType(CategoryIconTile), findsOneWidget);
  });

  testWidgets('add flow: amount, pick a category, save', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await openAddExpense(tester);
    expect(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text('Add Expense')), findsWidgets);
    expect(find.byKey(const Key('week-strip')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('expense-amount-field')), '42.50');
    await tester.tap(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text('Transport')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    expect(monthTotal(tester), '42.50  MRU');
    final saved = (expenseCubit.state as ExpenseLoaded).expenses.single;
    expect((saved.amountMinor, saved.categoryId), (4250, 'cat_transport'));
  });

  testWidgets('saving without an amount shows an error and stays open', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await openAddExpense(tester);
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

    await openAddExpense(tester);
    final y = DateTime.now().subtract(const Duration(days: 1));
    if (DateTime.now().weekday == DateTime.monday) {
      await tester.tap(find.byTooltip('Previous week'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(Key('day-${y.year}-${y.month}-${y.day}')));
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '1250');
    await tester.tap(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text('Food')));
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    final saved = (expenseCubit.state as ExpenseLoaded).expenses.single;
    expect(saved.amountMinor, 125000);
    expect((saved.spentOn.year, saved.spentOn.month, saved.spentOn.day), (y.year, y.month, y.day));
  });

  group('the Category a new Expense starts on', () {
    Future<void> pumpHome(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
    }

    Future<void> save(WidgetTester tester, String amount) async {
      await openAddExpense(tester);
      await tester.enterText(find.byKey(const Key('expense-amount-field')), amount);
      await tester.tap(find.byKey(const Key('save-expense-btn')));
      await tester.pumpAndSettle();
    }

    testWidgets('the first Expense has none: saving without one asks for a Category', (tester) async {
      await expenseCubit.load();
      await pumpHome(tester);

      await save(tester, '450');

      expect(find.text('Pick a Category'), findsOneWidget);
      expect(find.byType(ExpenseFormSheet), findsOneWidget);
      expect((expenseCubit.state as ExpenseLoaded).expenses, isEmpty);
    });

    testWidgets('after that, the last logged Expense\'s Category, not the first alphabetically', (tester) async {
      await expenseCubit.addExpense(amountMinor: 900, categoryId: 'cat_transport', spentOn: DateTime.now());
      await pumpHome(tester);

      await save(tester, '450');

      expect(find.byType(ExpenseFormSheet), findsNothing);
      final latest = (expenseCubit.state as ExpenseLoaded).expenses.firstWhere((e) => e.amountMinor == 45000);
      expect(latest.categoryId, 'cat_transport');
    });

    testWidgets('a deleted last Category is not picked for you', (tester) async {
      await categoryCubit.addCategory(name: 'Gym', icon: 'fitness_center', color: 0xFF4CAF50);
      final gymId = (categoryCubit.state as CategoryLoaded).categories.firstWhere((c) => c.name == 'Gym').id;
      await expenseCubit.addExpense(amountMinor: 900, categoryId: gymId, spentOn: DateTime.now());
      await categoryCubit.deleteCategory(gymId);
      await pumpHome(tester);

      await save(tester, '450');

      expect(find.text('Pick a Category'), findsOneWidget);
    });
  });

  testWidgets('an amount with more than two decimals is refused, with an example', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await openAddExpense(tester);
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '12.345');
    await tester.tap(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text('Food')));
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount like 450 or 12.50'), findsOneWidget);
    expect((expenseCubit.state as ExpenseLoaded).expenses, isEmpty);
  });

  group('stepping between months', () {
    // Sunday 18 October 2026.
    DateTime today() => DateTime(2026, 10, 18, 9, 30);
    Finder inCard(Finder f) => find.descendant(of: find.byKey(const Key('month-summary-card')), matching: f);
    Finder monthLabel(String text) =>
        find.descendant(of: find.byKey(const Key('month-header')), matching: find.text(text));

    String total(WidgetTester tester) => monthTotal(tester);

    Future<void> pumpHome(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(buildTestWidget(clock: today));
      await tester.pumpAndSettle();
    }

    IconButton arrow(WidgetTester tester, String tooltip) =>
        tester.widget<IconButton>(find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)));

    testWidgets('step back a month and see only that month\'s total', (tester) async {
      await expenseCubit.addExpense(amountMinor: 30000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 10, 18));
      await expenseCubit.addExpense(amountMinor: 12500, categoryId: 'cat_transport', spentOn: DateTime.utc(2026, 9, 30));
      await expenseCubit.addExpense(amountMinor: 4000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 9, 2));
      await pumpHome(tester);

      // Opens on the current month, with today and this week on the card.
      expect(monthLabel('October'), findsOneWidget);
      expect(inCard(find.text('Spent in October')), findsOneWidget);
      expect(total(tester), '300  MRU');
      expect(inCard(find.text('Today')), findsOneWidget);
      expect(arrow(tester, 'Next month').onPressed, isNull);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      expect(monthLabel('September'), findsOneWidget);
      expect(inCard(find.text('Spent in September')), findsOneWidget);
      expect(total(tester), '165  MRU');
      expect(inCard(find.text('Today')), findsNothing);
      expect(inCard(find.text('This week')), findsNothing);

      // September holds the first entry: no further back.
      expect(arrow(tester, 'Previous month').onPressed, isNull);
      expect(arrow(tester, 'Next month').onPressed, isNotNull);
    });

    testWidgets('this week counts the whole Monday-start week, even days in the month before', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      // Thursday 1 October 2026: the week began on Monday 28 September.
      await expenseCubit.addExpense(amountMinor: 9900, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 9, 27));
      await expenseCubit.addExpense(amountMinor: 1000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 9, 28));
      await expenseCubit.addExpense(amountMinor: 2000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 9, 30));
      await expenseCubit.addExpense(amountMinor: 500, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 10, 1));
      await tester.pumpWidget(buildTestWidget(clock: () => DateTime(2026, 10, 1, 12)));
      await tester.pumpAndSettle();

      expect(total(tester), '5  MRU');
      expect(inCard(find.text('35 MRU')), findsOneWidget); // this week: 10 + 20 + 5
    });

    testWidgets('a month with no Expenses shows zero, with no empty state on Home', (tester) async {
      await expenseCubit.addExpense(amountMinor: 30000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 10, 1));
      await expenseCubit.addExpense(amountMinor: 4000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 8, 20));
      await pumpHome(tester);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      expect(monthLabel('September'), findsOneWidget);
      expect(total(tester), '0  MRU');
      expect(find.byType(EmptyState), findsNothing);
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
      expect(total(tester), '40  MRU');

      await tester.fling(find.byKey(const Key('month-summary-card')), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(monthLabel('September'), findsOneWidget);

      await tester.tap(monthLabel('September'));
      await tester.pumpAndSettle();
      expect(monthLabel('October'), findsOneWidget);
      expect(total(tester), '300  MRU');
    });

    group('Category breakdown and filter', () {
      Finder sheet() => find.byKey(const Key('breakdown-sheet'));
      Finder inSheet(Finder f) => find.descendant(of: sheet(), matching: f);
      Finder row(String categoryId) => find.byKey(Key('breakdown-row-$categoryId'));

      Future<String> addDeletedGym() async {
        await categoryCubit.addCategory(name: 'Gym', icon: 'fitness_center', color: 0xFF4CAF50);
        return (categoryCubit.state as CategoryLoaded).categories.firstWhere((c) => c.name == 'Gym').id;
      }

      testWidgets('tapping the card lists the month per Category, deleted ones included, largest first',
          (tester) async {
        final gymId = await addDeletedGym();
        await expenseCubit.addExpense(amountMinor: 30000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 10, 18));
        await expenseCubit.addExpense(amountMinor: 7500, categoryId: gymId, spentOn: DateTime.utc(2026, 10, 5));
        await expenseCubit.addExpense(amountMinor: 12500, categoryId: 'cat_transport', spentOn: DateTime.utc(2026, 10, 3));
        await expenseCubit.addExpense(amountMinor: 4000, categoryId: 'cat_health', spentOn: DateTime.utc(2026, 9, 3));
        await categoryCubit.deleteCategory(gymId);
        await pumpHome(tester);

        await tester.tap(find.byKey(const Key('month-summary-card')));
        await tester.pumpAndSettle();

        expect(sheet(), findsOneWidget);
        expect(inSheet(find.text('Spent in October')), findsOneWidget);
        double top(String id) => tester.getTopLeft(row(id)).dy;
        expect(top('cat_food'), lessThan(top('cat_transport')));
        expect(top('cat_transport'), lessThan(top(gymId)));
        for (final (id, name, amount, share) in [
          ('cat_food', 'Food', '300 MRU', '60%'),
          ('cat_transport', 'Transport', '125 MRU', '25%'),
          (gymId, 'Gym', '75 MRU', '15%'),
        ]) {
          for (final text in [name, amount, share]) {
            expect(find.descendant(of: row(id), matching: find.text(text)), findsOneWidget, reason: '$name: $text');
          }
        }
        expect(inSheet(find.text('Health')), findsNothing); // September only
      });
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

  testWidgets('a list that cannot load says so plainly and offers to try again, without the raw error',
      (tester) async {
    await db.close(); // the phone's storage is gone: loading throws
    await expenseCubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load your Expenses"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('Error:'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
  });
}
