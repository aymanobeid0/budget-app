import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Adding an entry feels responsive: a light haptic tap on save, and rows
/// that animate in and out of the Home and Income lists.
void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late List<String> haptics;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, {bool reducedMotion = false}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    haptics = [];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    if (reducedMotion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    }
    await tester.pumpWidget(BudgetApp(
      categoryStore: CategoryStore(db),
      expenseLedger: ExpenseLedger(db),
      incomeLedger: IncomeLedger(db),
    ));
    await tester.pumpAndSettle();
  }

  Finder inSheet(Finder f) => find.descendant(of: find.byType(ExpenseFormSheet), matching: f);

  /// Fills and saves the Add sheet, leaving the closing route to settle.
  Future<void> addExpense(WidgetTester tester, String amount) async {
    await tester.tap(find.byKey(const Key('nav-expenses')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-expense-btn')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount-field')), amount);
    await tester.tap(inSheet(find.text('Transport')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-expense-btn')));
  }

  /// How opaque [f] is drawn, through any fading ancestors.
  double opacityOf(WidgetTester tester, Finder f) {
    var opacity = 1.0;
    tester.element(f).visitAncestorElements((e) {
      final w = e.widget;
      if (w is FadeTransition) opacity *= w.opacity.value;
      if (w is Opacity) opacity *= w.opacity;
      return true;
    });
    return opacity;
  }

  /// Pumps frame by frame until [f] shows, and returns its opacity then.
  Future<double> opacityWhenItAppears(WidgetTester tester, Finder f) async {
    for (var i = 0; i < 120 && f.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(f, findsOneWidget);
    return opacityOf(tester, f);
  }

  testWidgets('a new Expense fades into the Expenses list', (tester) async {
    await pumpApp(tester);

    await addExpense(tester, '42');

    expect(await opacityWhenItAppears(tester, find.text('- 42')), lessThan(1));
    await tester.pumpAndSettle();
    expect(opacityOf(tester, find.text('- 42')), 1);
  });

  /// Pumps frame by frame until [f] is gone; true if it was ever drawn
  /// part-faded on the way out.
  Future<bool> fadesOut(WidgetTester tester, Finder f) async {
    var faded = false;
    for (var i = 0; i < 120 && f.evaluate().isNotEmpty; i++) {
      final o = opacityOf(tester, f);
      if (o > 0 && o < 1) faded = true;
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(f, findsNothing);
    return faded;
  }

  /// [f] within the Expenses page only: Home, in the background, lists the same Expense.
  Finder onExpensesPage(Finder f) =>
      find.descendant(of: find.byKey(const Key('expense-list-screen'), skipOffstage: false), matching: f);

  Future<void> deleteFromSheet(WidgetTester tester, Finder row) async {
    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-expense-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
  }

  testWidgets('a deleted Expense fades out of the Expenses list', (tester) async {
    await pumpApp(tester);
    await addExpense(tester, '42');
    await tester.pumpAndSettle();

    await deleteFromSheet(tester, find.text('- 42'));

    expect(await fadesOut(tester, onExpensesPage(find.text('- 42', skipOffstage: false))), isTrue);
  });

  Future<void> addIncomeOnIncomeTab(WidgetTester tester, String amount) async {
    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-income-btn')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount-field')), amount);
    await tester.tap(inSheet(find.text('Salary')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-expense-btn')));
  }

  testWidgets('a new Income fades into the Income list, and fades out when deleted', (tester) async {
    await pumpApp(tester);

    await addIncomeOnIncomeTab(tester, '3500');
    expect(await opacityWhenItAppears(tester, find.text('+3,500')), lessThan(1));
    await tester.pumpAndSettle();
    expect(haptics, ['HapticFeedbackType.lightImpact']);

    await deleteFromSheet(tester, find.text('+3,500'));
    expect(await fadesOut(tester, find.text('+3,500', skipOffstage: false)), isTrue);
  });

  testWidgets('the last Income leaves above the empty state, as on Home', (tester) async {
    await pumpApp(tester);
    await addIncomeOnIncomeTab(tester, '3500');
    await tester.pumpAndSettle();

    await deleteFromSheet(tester, find.text('+3,500'));
    final leaving = find.text('+3,500', skipOffstage: false);
    final empty = find.text('No Income yet', skipOffstage: false);
    for (var i = 0; i < 120 && empty.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(leaving, findsOneWidget, reason: 'still fading out when the empty state shows');
    expect(tester.getTopLeft(leaving).dy, lessThan(tester.getTopLeft(empty).dy));
    await tester.pumpAndSettle();
  });

  testWidgets('with reduced motion, Expenses appear and vanish without animating', (tester) async {
    await pumpApp(tester, reducedMotion: true);

    await addExpense(tester, '42');
    expect(await opacityWhenItAppears(tester, find.text('- 42')), 1);
    await tester.pumpAndSettle();

    await deleteFromSheet(tester, find.text('- 42'));
    expect(await fadesOut(tester, onExpensesPage(find.text('- 42', skipOffstage: false))), isFalse);
  });

  testWidgets('saving an Expense from the Add sheet gives a light haptic tap', (tester) async {
    await pumpApp(tester);

    await addExpense(tester, '42');
    await tester.pumpAndSettle();

    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('a rejected save gives no haptic tap', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('nav-expenses')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-expense-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    expect(haptics, isEmpty);
  });
}
