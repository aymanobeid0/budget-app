import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/format/money.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:budget_app/features/settings/cubit/currency_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
    AddSheetMemory.reset();
  });

  tearDown(() => db.close());

  /// Launches the app the way main.dart does: the saved Currency, else MRU.
  Future<void> launch(WidgetTester tester, CurrencyStorage storage) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final cubit = CurrencyCubit(storage: storage, initial: await storage.read() ?? Currency.mru);
    addTearDown(cubit.close);
    await tester.pumpWidget(BudgetApp(
      categoryStore: CategoryStore(db),
      expenseLedger: ExpenseLedger(db),
      incomeLedger: IncomeLedger(db),
      currencyCubit: cubit,
    ));
    await tester.pumpAndSettle();
  }

  Finder onHome(String text) =>
      find.descendant(of: find.byKey(const Key('month-summary-card')), matching: find.textContaining(text));

  Future<void> pickCurrency(WidgetTester tester, Currency currency) async {
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-currency-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('currency-option-${currency.name}')));
    await tester.pumpAndSettle();
  }

  testWidgets('first launch shows amounts in MRU', (tester) async {
    await launch(tester, InMemoryCurrencyStorage());

    expect(onHome('MRU'), findsWidgets);
  });

  testWidgets('picking a Currency in Settings relabels amounts right away', (tester) async {
    await launch(tester, InMemoryCurrencyStorage());

    await pickCurrency(tester, Currency.eur);
    expect(find.descendant(of: find.byKey(const Key('profile-currency-row')), matching: find.text('EUR')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-expenses')));
    await tester.pumpAndSettle();
    expect(onHome('EUR'), findsWidgets);
    expect(onHome('MRU'), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('net-card')), matching: find.textContaining('EUR')),
        findsWidgets);

    await tester.tap(find.byKey(const Key('add-expense-fab')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text('EUR')), findsOneWidget);
  });

  testWidgets('Income totals use the chosen Currency', (tester) async {
    await launch(tester, InMemoryCurrencyStorage(Currency.usd));
    await tester.tap(find.byKey(const Key('add-expense-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('entry-kind-income')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '1000');
    await tester.tap(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text('Salary')));
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-income')));
    await tester.pumpAndSettle();

    expect(find.textContaining('USD'), findsWidgets);
    expect(find.textContaining('MRU'), findsNothing);
  });

  testWidgets('the chosen Currency survives a restart', (tester) async {
    final storage = InMemoryCurrencyStorage();
    await launch(tester, storage);
    await pickCurrency(tester, Currency.sar);

    await tester.pumpWidget(const SizedBox());
    await launch(tester, storage);

    expect(onHome('SAR'), findsWidgets);
  });
}
