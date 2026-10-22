import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/router/app_shell.dart';
import 'package:budget_app/core/sync/cloud_sync_client.dart';
import 'package:budget_app/core/sync/sync_engine.dart';
import 'package:budget_app/core/theme/theme_cubit.dart';
import 'package:budget_app/core/theme/widgets.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/expenses/ui/expense_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Reachable cloud with no rows; counts how many syncs reached it.
class _CountingCloud implements CloudSyncClient {
  int syncs = 0;

  @override
  String? get currentUserId => 'user_1';
  @override
  Future<String?> ensureAuthenticated() async {
    syncs++;
    return 'user_1';
  }

  @override
  Future<void> upsertCategories(List<Map<String, dynamic>> rows) async {}
  @override
  Future<void> upsertExpenses(List<Map<String, dynamic>> rows) async {}
  @override
  Future<void> upsertIncomeSources(List<Map<String, dynamic>> rows) async {}
  @override
  Future<void> upsertIncome(List<Map<String, dynamic>> rows) async {}
  @override
  Future<List<Map<String, dynamic>>> fetchCategories() async => [];
  @override
  Future<List<Map<String, dynamic>>> fetchExpenses() async => [];
  @override
  Future<List<Map<String, dynamic>>> fetchIncomeSources() async => [];
  @override
  Future<List<Map<String, dynamic>>> fetchIncome() async => [];
}

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

  testWidgets('shell shows Home, Income, Expenses, Consultant and Profile tabs and starts on Home', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    expect(find.byType(AppNavBar), findsOneWidget);
    for (final key in ['home', 'income', 'expenses', 'consultant', 'settings']) {
      expect(find.byKey(Key('nav-$key')), findsOneWidget);
    }
    expect(find.byKey(const Key('nav-categories')), findsNothing);
    expect(find.byKey(const Key('expenses-screen')), findsOneWidget);
    // Home adds an Expense, from the button at the top left of its header;
    // the tab bar holds tabs only.
    expect(find.byTooltip('Add expense'), findsOneWidget);
    expect(find.descendant(of: find.byType(ScreenHeader), matching: find.byKey(const Key('add-expense-btn'))),
        findsOneWidget);
    expect(find.descendant(of: find.byType(AppNavBar), matching: find.byIcon(Icons.add_rounded)), findsNothing);
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
  });

  testWidgets('Categories open only from Profile, and Back returns there', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();
    // Neither Home nor the Expenses tab has a Categories button.
    expect(find.byTooltip('Categories'), findsNothing);
    await tester.tap(find.byKey(const Key('nav-expenses')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Categories'), findsNothing);

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-categories-row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('categories-screen')), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-screen')), findsOneWidget);
    expect(find.byKey(const Key('categories-screen')), findsNothing);
  });

  testWidgets("the Add Expense page's + chip makes a Category and picks it, keeping the amount", (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-expense-btn')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '42');

    await tester.tap(find.byKey(const Key('picker-add-chip')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Gym');
    await tester.tap(find.text('Create Category'));
    await tester.pumpAndSettle();

    final form = find.byType(ExpenseFormSheet);
    expect(find.descendant(of: form, matching: find.text('Gym')), findsOneWidget);
    expect(find.descendant(of: form, matching: find.text('42')), findsOneWidget);

    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();
    final saved = (await ledger.loadExpenses()).single;
    final gym = (await store.loadCategories()).firstWhere((c) => c.name == 'Gym');
    expect(saved.categoryId, gym.id);
  });

  testWidgets('the Expenses tab opens the Expenses page, and is active only while it shows', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    // The bar colors its icons through IconTheme, so read the color that applies.
    Color iconColor(String key) => IconTheme.of(
        tester.element(find.descendant(of: find.byKey(Key(key)), matching: find.byType(Icon)).first)).color!;
    final inactive = iconColor('nav-income');
    final active = iconColor('nav-home');
    expect(iconColor('nav-expenses'), inactive); // grey like the other tabs

    await tester.tap(find.byKey(const Key('nav-expenses')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expense-list-screen')), findsOneWidget);
    expect(iconColor('nav-expenses'), active);
    expect(iconColor('nav-home'), inactive);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(iconColor('nav-expenses'), inactive);
  });

  testWidgets("the Expenses page's Add Expense button sits top left and opens Add Expense with no Income option",
      (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-expenses')));
    await tester.pumpAndSettle();

    // At the top left of the page, beside the centered title.
    final screen = tester.getRect(find.byType(MaterialApp));
    final add = tester.getRect(find.byKey(const Key('add-expense-btn')));
    final title = tester.getRect(find.descendant(of: find.byType(ScreenHeader), matching: find.text('Expenses')));
    expect(add.center.dx, lessThan(screen.width / 4));
    expect(add.right, lessThanOrEqualTo(title.left));
    expect(title.center.dx, moreOrLessEquals(screen.center.dx));

    await tester.tap(find.byKey(const Key('add-expense-btn')));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseFormSheet), findsOneWidget);
    expect(find.text('Add Expense'), findsWidgets);
    expect(find.byKey(const Key('week-strip')), findsOneWidget);
    // Within the form: the tab bar's own "Income" label is not an option.
    final form = find.byType(ExpenseFormSheet);
    expect(find.descendant(of: form, matching: find.text('Income')), findsNothing);
    expect(find.descendant(of: form, matching: find.text('Income Source')), findsNothing);
  });

  testWidgets('a saved Expense shows on the Expenses page under its day', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-expenses')));
    await tester.pumpAndSettle();
    expect(find.text('No Expenses yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-expense-btn')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '42');
    await tester.tap(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text('Food')));
    await tester.tap(find.byKey(const Key('save-expense-btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('expense-list-screen')), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('- 42'), findsOneWidget);
    expect(find.byKey(const Key('expense-total')), findsOneWidget);
  });

  testWidgets('app starts in light mode', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(Theme.of(tester.element(find.byKey(const Key('expenses-screen')))).brightness, Brightness.light);
  });

  testWidgets('the Profile switch is the one dark-mode control: it toggles both ways and saves the choice',
      (tester) async {
    final storage = InMemoryThemeStorage();
    final cubit = ThemeCubit(storage: storage);
    addTearDown(cubit.close);

    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger, themeCubit: cubit));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('theme-toggle')), findsNothing); // no header toggle on Home
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('theme-toggle')), findsNothing); // nor in Profile's header

    final darkSwitch = find.byKey(const Key('dark-mode-switch'));
    await Scrollable.ensureVisible(tester.element(darkSwitch), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(darkSwitch);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byKey(const Key('settings-screen')))).brightness, Brightness.dark);
    expect(await storage.read(), ThemeMode.dark);

    await tester.tap(darkSwitch);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byKey(const Key('settings-screen')))).brightness, Brightness.light);
    expect(await storage.read(), ThemeMode.light);
  });

  testWidgets('Settings switch turns dark mode on', (tester) async {
    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    // Centred, so it isn't under the floating nav bar.
    await Scrollable.ensureVisible(tester.element(find.byKey(const Key('dark-mode-switch'))), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dark-mode-switch')));
    await tester.pumpAndSettle();

    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
  });

  testWidgets('returning the app to the foreground syncs', (tester) async {
    final cloud = _CountingCloud();
    final engine = SyncEngine(db: db, client: cloud);
    addTearDown(engine.dispose);

    await tester.pumpWidget(BudgetApp(categoryStore: store, expenseLedger: ledger, syncEngine: engine));
    await tester.pumpAndSettle();
    expect(cloud.syncs, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(cloud.syncs, 1);
  });
}
