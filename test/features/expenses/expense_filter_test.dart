import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/month/chosen_month_cubit.dart';
import 'package:budget_app/core/theme/empty_state.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The Category filter: picked from a month's breakdown on Home or on the
/// Expenses tab, it shows on the Expenses tab.
void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
  });

  tearDown(() => db.close());

  // Sunday 18 October 2026.
  DateTime today() => DateTime(2026, 10, 18, 9, 30);
  final stamp = DateTime.utc(2026, 1, 1);

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = CategoryStore(db);
    final ledger = ExpenseLedger(db);
    await store.loadCategories(); // the preset Categories the entries point at
    var n = 0;
    Future<void> spend(int minor, String categoryId, DateTime on) => ledger.logExpense(Expense(
        id: 'exp_${n++}', amountMinor: minor, categoryId: categoryId, spentOn: on, createdAt: stamp, updatedAt: stamp));
    await spend(30000, 'cat_food', DateTime.utc(2026, 10, 18));
    await spend(12500, 'cat_transport', DateTime.utc(2026, 10, 3));
    await spend(4000, 'cat_transport', DateTime.utc(2026, 9, 3));
    await spend(2000, 'cat_food', DateTime.utc(2026, 8, 3));
    final chosenMonth = ChosenMonthCubit(clock: today);
    addTearDown(chosenMonth.close);
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger, chosenMonthCubit: chosenMonth));
    await tester.pumpAndSettle();
  }

  Finder chip() => find.byKey(const Key('group-filter-chip'));
  Finder row(String categoryId) => find.byKey(Key('breakdown-row-$categoryId'));

  Future<void> pickFromHome(WidgetTester tester, String categoryId) async {
    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('month-summary-card')));
    await tester.pumpAndSettle();
    await tester.tap(row(categoryId));
    await tester.pumpAndSettle();
  }

  testWidgets('a Category picked in Home\'s breakdown opens the Expenses tab filtered to it', (tester) async {
    await pumpApp(tester);

    await pickFromHome(tester, 'cat_transport');

    expect(find.byKey(const Key('expense-list-screen')), findsOneWidget);
    expect(find.descendant(of: chip(), matching: find.text('Transport')), findsOneWidget);
    expect(find.text('- 125'), findsOneWidget);
    expect(find.text('- 300'), findsNothing);

    // The filter stays when stepping back a month.
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(chip(), findsOneWidget);
    expect(find.text('- 40'), findsOneWidget);

    // August has no Transport: the empty state, with the chip still there.
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(chip(), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);

    await tester.tap(find.descendant(of: chip(), matching: find.byIcon(Icons.close_rounded)));
    await tester.pumpAndSettle();
    expect(chip(), findsNothing);
    expect(find.text('- 20'), findsOneWidget);
  });

  testWidgets('picking the same Category again after clearing filters again', (tester) async {
    await pumpApp(tester);

    await pickFromHome(tester, 'cat_food');
    expect(find.descendant(of: chip(), matching: find.text('Food')), findsOneWidget);
    await tester.tap(find.descendant(of: chip(), matching: find.byIcon(Icons.close_rounded)));
    await tester.pumpAndSettle();
    expect(chip(), findsNothing);

    await pickFromHome(tester, 'cat_food');
    expect(find.descendant(of: chip(), matching: find.text('Food')), findsOneWidget);
    expect(find.text('- 125'), findsNothing);
  });

  testWidgets('the Expenses tab\'s own breakdown filters its list too', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-expenses')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('expense-total')));
    await tester.pumpAndSettle();
    await tester.tap(row('cat_food'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: chip(), matching: find.text('Food')), findsOneWidget);
    expect(find.text('- 300'), findsOneWidget);
    expect(find.text('- 125'), findsNothing);
  });

  testWidgets('Categories count the month the app shows', (tester) async {
    await pumpApp(tester);
    Future<void> openCategories() async {
      await tester.tap(find.byKey(const Key('nav-settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-categories-row')));
      await tester.pumpAndSettle();
    }
    Finder subtitle(String id, String text) =>
        find.descendant(of: find.byKey(Key('category-item-$id')), matching: find.text(text));

    await openCategories();
    expect(subtitle('cat_food', '1 Expense this month'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    await openCategories();
    expect(subtitle('cat_transport', '1 Expense in September'), findsOneWidget);
    expect(subtitle('cat_food', 'No Expenses in September'), findsOneWidget);
  });
}
