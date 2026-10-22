import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/router/app_shell.dart';
import 'package:budget_app/core/theme/tokens.dart';
import 'package:budget_app/core/theme/widgets.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// How the shell adapts to wide windows and large text sizes.
void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, Size size, {double textScale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = CategoryStore(db);
    final ledger = ExpenseLedger(db);
    await store.loadCategories();
    await ledger.loadExpenses();
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();
  }

  group('a wide Android or desktop window', () {
    testWidgets('swaps the tab bar for a labeled rail, the add button staying in the page header', (tester) async {
      await pumpApp(tester, const Size(1280, 800));

      expect(find.byType(AppNavRail), findsOneWidget);
      expect(find.byType(AppNavBar), findsNothing);
      final rail = tester.getRect(find.byType(NavigationRail));
      final add = tester.getRect(find.byKey(const Key('add-expense-btn')));
      expect(rail.contains(add.center), isFalse);
      expect(find.descendant(of: find.byType(ScreenHeader), matching: find.byKey(const Key('add-expense-btn'))),
          findsOneWidget);
      expect(find.descendant(of: find.byType(NavigationRail), matching: find.text('Consultant')), findsOneWidget);

      await tester.tap(find.byKey(const Key('add-expense-btn')));
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseFormSheet), findsOneWidget);
    });

    testWidgets('rail destinations change the tab, and the add button follows the tab', (tester) async {
      await pumpApp(tester, const Size(1280, 800));

      await tester.tap(find.descendant(of: find.byType(NavigationRail), matching: find.text('Expenses')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expense-list-screen')), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(NavigationRail), matching: find.text('Consultant')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('consultant-screen')), findsOneWidget);
      expect(find.byKey(const Key('add-expense-btn')), findsNothing);
    });

    testWidgets('keeps each page a readable column instead of stretching it', (tester) async {
      await pumpApp(tester, const Size(1280, 800));

      expect(tester.getRect(find.byKey(const Key('expenses-screen'))).width,
          lessThanOrEqualTo(AppLayout.readableWidth));
      await tester.tap(find.byKey(const Key('add-expense-btn')));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(ExpenseFormSheet)).width, lessThanOrEqualTo(AppLayout.readableWidth));
    });
  });

  testWidgets('an iPad keeps its tab bar at any width, with the page still a readable column', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await pumpApp(tester, const Size(1180, 820));

    expect(find.byType(AppNavBar), findsOneWidget);
    expect(find.byType(AppNavRail), findsNothing);
    final page = tester.getRect(find.byKey(const Key('expenses-screen')));
    expect(page.width, lessThanOrEqualTo(AppLayout.readableWidth));
    // The add button stays inside the column, at its top left.
    final add = tester.getRect(find.byKey(const Key('add-expense-btn')));
    expect(add.left, greaterThanOrEqualTo(page.left));
    expect(add.left, lessThan(page.left + 40));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a phone keeps the tab bar and full-width pages', (tester) async {
    await pumpApp(tester, const Size(390, 844));

    expect(find.byType(AppNavBar), findsOneWidget);
    expect(tester.getRect(find.byKey(const Key('expenses-screen'))).width, 390);
  });

  group('at a large text size', () {
    // The tab bar is icons only, so nothing in it wraps; each tab still
    // carries its name for screen readers and long press.
    testWidgets('tabs keep their names as tooltips, with no labels to wrap', (tester) async {
      await pumpApp(tester, const Size(390, 844), textScale: 2);

      expect(find.descendant(of: find.byType(AppNavBar), matching: find.text('Consultant')), findsNothing);
      expect(find.descendant(of: find.byType(AppNavBar), matching: find.byTooltip('Consultant')), findsOneWidget);
    });

    testWidgets('the rest of the app scales: screen titles grow with the setting', (tester) async {
      await pumpApp(tester, const Size(390, 844), textScale: 2);

      final title = find.descendant(of: find.byType(ScreenHeader), matching: find.text('Home'));
      expect(MediaQuery.textScalerOf(tester.element(title)).scale(20), 36);
    });

    testWidgets('the hero card stacks Today and This week instead of cutting the amounts off', (tester) async {
      await pumpApp(tester, const Size(390, 844), textScale: 1.5);

      final today = tester.getRect(find.text('Today'));
      final week = tester.getRect(find.text('This week'));
      expect(week.top, greaterThan(today.bottom)); // one above the other
      expect(find.textContaining('…'), findsNothing);
    });
  });
}
