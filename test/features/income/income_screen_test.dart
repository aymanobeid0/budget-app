import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/month/chosen_month_cubit.dart';
import 'package:budget_app/core/theme/theme_cubit.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/categories/cubit/category_cubit.dart';
import 'package:budget_app/features/expenses/cubit/expense_cubit.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/income/cubit/income_cubit.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:budget_app/features/income/ui/income_screen.dart';
import 'package:budget_app/features/settings/cubit/currency_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late IncomeCubit incomeCubit;
  late ExpenseCubit expenseCubit;
  late CategoryCubit categoryCubit;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
    incomeCubit = IncomeCubit(IncomeLedger(db));
    categoryCubit = CategoryCubit(CategoryStore(db));
    expenseCubit = ExpenseCubit(ExpenseLedger(db));
    await categoryCubit.load(); // Seeds the default Categories.
    await incomeCubit.load();
    await expenseCubit.load();
  });

  tearDown(() async {
    await incomeCubit.close();
    await expenseCubit.close();
    await categoryCubit.close();
    await db.close();
  });

  // Sunday 18 October 2026.
  DateTime today() => DateTime(2026, 10, 18, 9, 30);
  Finder monthLabel(String text) =>
      find.descendant(of: find.byKey(const Key('month-header')), matching: find.text(text));
  Finder inTotal(Finder f) => find.descendant(of: find.byKey(const Key('income-total')), matching: f);
  IconButton arrow(WidgetTester tester, String tooltip) =>
      tester.widget<IconButton>(find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)));

  Future<void> pumpIncome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<IncomeCubit>.value(value: incomeCubit),
          BlocProvider<ExpenseCubit>.value(value: expenseCubit),
          BlocProvider<CategoryCubit>.value(value: categoryCubit),
          BlocProvider<ChosenMonthCubit>(create: (_) => ChosenMonthCubit(clock: today)),
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<CurrencyCubit>(create: (_) => CurrencyCubit()),
        ],
        child: const IncomeScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('step back a month and see only that month\'s Income, grouped by day', (tester) async {
    await incomeCubit.addIncome(amountMinor: 100000, sourceId: 'src_salary', paidOn: DateTime.utc(2026, 10, 1));
    await incomeCubit.addIncome(amountMinor: 25000, sourceId: 'src_freelance', paidOn: DateTime.utc(2026, 9, 30));
    await incomeCubit.addIncome(amountMinor: 7000, sourceId: 'src_other', paidOn: DateTime.utc(2026, 9, 30));
    await incomeCubit.addIncome(amountMinor: 4000, sourceId: 'src_other', paidOn: DateTime.utc(2026, 9, 2));
    await pumpIncome(tester);

    expect(monthLabel('October'), findsOneWidget);
    expect(inTotal(find.text('Income in October')), findsOneWidget);
    expect(inTotal(find.text('1,000 MRU')), findsOneWidget);
    expect(find.text('+1,000'), findsOneWidget);
    expect(find.text('+250'), findsNothing);
    expect(arrow(tester, 'Next month').onPressed, isNull);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();

    expect(monthLabel('September'), findsOneWidget);
    expect(inTotal(find.text('Income in September')), findsOneWidget);
    expect(inTotal(find.text('360 MRU')), findsOneWidget);
    expect(find.text('+250'), findsOneWidget);
    expect(find.text('+70'), findsOneWidget);
    expect(find.text('+40'), findsOneWidget);
    expect(find.text('+1,000'), findsNothing);
    // Still grouped by day, with the day's total.
    expect(find.text('Wed, 30 Sep'), findsOneWidget);
    expect(find.text('320 MRU'), findsOneWidget);
    expect(find.text('Wed, 2 Sep'), findsOneWidget);

    // September holds the first entry: no further back.
    expect(arrow(tester, 'Previous month').onPressed, isNull);
  });

  testWidgets('a month with no Income shows its own empty state', (tester) async {
    await incomeCubit.addIncome(amountMinor: 100000, sourceId: 'src_salary', paidOn: DateTime.utc(2026, 10, 1));
    await incomeCubit.addIncome(amountMinor: 4000, sourceId: 'src_other', paidOn: DateTime.utc(2026, 8, 20));
    await pumpIncome(tester);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();

    expect(monthLabel('September'), findsOneWidget);
    expect(inTotal(find.text('0 MRU')), findsOneWidget);
    expect(find.text('No Income in September'), findsOneWidget);
    expect(find.text('No Income yet'), findsNothing);
    expect(find.text('+1,000'), findsNothing);
    expect(find.text('+40'), findsNothing);
  });

  testWidgets('an earlier Expense lets the Income tab step back to its month too', (tester) async {
    await incomeCubit.addIncome(amountMinor: 100000, sourceId: 'src_salary', paidOn: DateTime.utc(2026, 10, 1));
    await expenseCubit.addExpense(amountMinor: 3000, categoryId: 'cat_food', spentOn: DateTime.utc(2026, 9, 5));
    await pumpIncome(tester);

    expect(arrow(tester, 'Previous month').onPressed, isNotNull);
    await tester.fling(find.byKey(const Key('income-total')), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();

    expect(monthLabel('September'), findsOneWidget);
    expect(find.text('No Income in September'), findsOneWidget);
    expect(arrow(tester, 'Previous month').onPressed, isNull);
  });
}
