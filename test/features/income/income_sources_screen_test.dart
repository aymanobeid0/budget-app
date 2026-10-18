import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/theme/empty_state.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late IncomeLedger incomeLedger;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
    incomeLedger = IncomeLedger(db);
    AddSheetMemory.reset();
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BudgetApp(
      categoryStore: CategoryStore(db),
      expenseLedger: ExpenseLedger(db),
      incomeLedger: incomeLedger,
    ));
    await tester.pumpAndSettle();
  }

  Future<void> openSources(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-income-sources-row')));
    await tester.pumpAndSettle();
  }

  Finder inSheet(Finder f) => find.descendant(of: find.byType(ExpenseFormSheet), matching: f);

  testWidgets('a new Income Source from Profile shows up in the Add sheet picker', (tester) async {
    await pumpApp(tester);
    await openSources(tester);

    expect(find.byKey(const Key('income-sources-screen')), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Food'), findsNothing); // Categories never appear here

    await tester.tap(find.byKey(const Key('add-income-source-btn')));
    await tester.pumpAndSettle();
    expect(find.text('New Income Source'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('category-name-field')), 'Dental clinic');
    await tester.ensureVisible(find.byKey(const Key('save-category-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-category-btn')));
    await tester.pumpAndSettle();
    expect(find.text('Dental clinic'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-expense-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('entry-kind-income')));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Dental clinic')), findsOneWidget);
  });

  testWidgets('Income Sources are also reachable from the Income tab', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('income-sources-btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('income-sources-screen')), findsOneWidget);
  });

  testWidgets('a deleted source leaves the picker but its past Income keeps its name', (tester) async {
    await incomeLedger.loadSources();
    await pumpApp(tester);

    // Log one Salary Income.
    await tester.tap(find.byKey(const Key('add-expense-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('entry-kind-income')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '900');
    await tester.tap(inSheet(find.text('Salary')));
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    await openSources(tester);
    await tester.tap(find.descendant(
      of: find.byKey(const Key('income-source-item-src_salary')),
      matching: find.byTooltip('More options'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('income-source-item-src_salary')), findsNothing);

    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('+900'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-expense-fab')));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Salary')), findsNothing);
  });

  testWidgets('with every Income Source deleted, the shared empty state offers to add one', (tester) async {
    for (final s in await incomeLedger.loadSources()) {
      await incomeLedger.deleteSource(s.id);
    }
    await pumpApp(tester);
    await openSources(tester);

    final empty = find.byType(EmptyState);
    expect(find.descendant(of: empty, matching: find.text('No Income Sources yet')), findsOneWidget);
    await tester.tap(find.descendant(of: empty, matching: find.byKey(const Key('add-first-income-source'))));
    await tester.pumpAndSettle();

    expect(find.text('New Income Source'), findsOneWidget);
  });
}
