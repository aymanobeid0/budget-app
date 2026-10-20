import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/sync/cloud_sync_client.dart';
import 'package:budget_app/core/sync/sync_engine.dart';
import 'package:budget_app/features/account/account_service.dart';
import 'package:budget_app/features/account/data/account_prefs.dart';
import 'package:budget_app/features/account/data/auth_gateway.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A guest session that never talks to a server.
class _GuestAuth implements AuthGateway {
  @override
  String? get accountEmail => null;
  @override
  Future<void> signUp({required String email, required String password}) async {}
  @override
  Future<void> signIn({required String email, required String password}) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> signInAsGuest() async {}
}

/// Reachable cloud with no rows.
class _EmptyCloud implements CloudSyncClient {
  @override
  String? get currentUserId => 'guest_1';
  @override
  Future<String?> ensureAuthenticated() async => 'guest_1';
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

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
  });

  tearDown(() => db.close());

  testWidgets('the account dialog opens centred above the nav bar, so none of it is hidden', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final engine = SyncEngine(db: db, client: _EmptyCloud());
    addTearDown(engine.dispose);
    final service = AccountService(
      db: db,
      auth: _GuestAuth(),
      syncEngine: engine,
      prefsStorage: InMemoryAccountPrefsStorage(),
    );
    await service.init();

    await tester.pumpWidget(BudgetApp(
      categoryStore: CategoryStore(db),
      expenseLedger: ExpenseLedger(db),
      syncEngine: engine,
      accountService: service,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-account-btn')));
    await tester.pumpAndSettle();

    // Its last row is reachable and the nav bar sits behind it.
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byKey(const Key('account-mode-toggle')).hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('nav-settings')).hitTestable(), findsNothing);

    // Centred: the gap above it matches the gap below it.
    // The visible card is the Material inside Dialog (Dialog itself fills the screen).
    final card = find.descendant(of: find.byType(Dialog), matching: find.byType(Material)).first;
    final screen = tester.getRect(find.byType(Scaffold).first);
    final dialog = tester.getRect(card);
    expect(dialog.height, lessThan(screen.height - 100));
    expect((dialog.top - screen.top) - (screen.bottom - dialog.bottom), moreOrLessEquals(0, epsilon: 1));

    // The submit button is flat, and the mode switch is a "Sign in" / "Sign up" link.
    final shadows = tester
        .widgetList<DecoratedBox>(find.ancestor(
          of: find.byKey(const Key('account-submit-btn')),
          matching: find.byType(DecoratedBox),
        ))
        .map((b) => b.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.boxShadow?.isNotEmpty ?? false);
    expect(shadows, isEmpty);
    expect(find.text('Already have an account? '), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('account-mode-toggle')), matching: find.text('Sign in')),
        findsOneWidget);

    // The link is plain text: no button, so no background or press highlight.
    final toggle = find.byKey(const Key('account-mode-toggle'));
    expect(find.descendant(of: toggle, matching: find.text('Sign in')), findsOneWidget);
    for (final type in [TextButton, InkWell, Material, DecoratedBox, ColoredBox]) {
      expect(find.descendant(of: toggle, matching: find.byType(type)), findsNothing, reason: 'link has a $type');
    }

    // Tapping the question does nothing; only the link switches mode.
    await tester.tap(find.text('Already have an account? '));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-confirm-field')), findsOneWidget);

    await tester.tap(find.byKey(const Key('account-mode-toggle')));
    await tester.pumpAndSettle();
    expect(find.text("Don't have an account? "), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('account-mode-toggle')), matching: find.text('Sign up')),
        findsOneWidget);
    expect(find.byKey(const Key('account-confirm-field')), findsNothing);
    await tester.tap(find.byKey(const Key('account-mode-toggle')));
    await tester.pumpAndSettle();

    // With the keyboard up it moves above it and scrolls to the submit button.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    await tester.pumpAndSettle();
    expect(tester.getRect(card).bottom, lessThanOrEqualTo(844 - 300));
    await tester.ensureVisible(find.byKey(const Key('account-submit-btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-submit-btn')).hitTestable(), findsOneWidget);
  });
}
