import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/router/app_shell.dart';
import 'package:budget_app/core/theme/theme_cubit.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late CategoryStore store;
  late ExpenseLedger ledger;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    store = CategoryStore(db);
    ledger = ExpenseLedger(db);
  });

  tearDown(() => db.close());

  testWidgets('shell shows Home, Consultant and Profile tabs plus the add button and starts on Expenses', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    expect(find.byType(AppNavBar), findsOneWidget);
    for (final label in ['Expenses', 'Consultant', 'Settings']) {
      expect(find.byKey(Key('nav-${label.toLowerCase()}')), findsOneWidget);
    }
    expect(find.byKey(const Key('nav-categories')), findsNothing);
    expect(find.byKey(const Key('add-expense-fab')), findsOneWidget);
    expect(find.byKey(const Key('expenses-screen')), findsOneWidget);
  });

  testWidgets('tapping a tab switches the visible screen', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-consultant')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('consultant-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-screen')), findsOneWidget);
  });

  testWidgets('Categories open from Profile, keep working, and go back', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-categories-row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('categories-screen')), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-screen')), findsOneWidget);

    // The add button still opens the Add sheet from Categories.
    await tester.tap(find.byKey(const Key('profile-categories-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-expense-fab')));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseFormSheet), findsOneWidget);
  });

  testWidgets('raised add button in the nav bar opens the expense sheet', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-expense-fab')));
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseFormSheet), findsOneWidget);
    expect(find.text('Add Expense'), findsWidgets);
    expect(find.byKey(const Key('week-strip')), findsOneWidget);
  });

  testWidgets('app starts in light mode', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(Theme.of(tester.element(find.byKey(const Key('expenses-screen')))).brightness, Brightness.light);
  });

  testWidgets('sun/moon button toggles dark mode and back, and saves the choice', (tester) async {
    final storage = InMemoryThemeStorage();
    final cubit = ThemeCubit(storage: storage);
    addTearDown(cubit.close);

    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger, themeCubit: cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byKey(const Key('expenses-screen')))).brightness, Brightness.dark);
    expect(await storage.read(), ThemeMode.dark);

    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byKey(const Key('expenses-screen')))).brightness, Brightness.light);
    expect(await storage.read(), ThemeMode.light);
  });

  testWidgets('Settings switch turns dark mode on', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dark-mode-switch')));
    await tester.pumpAndSettle();

    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
  });
}
