import 'dart:async';

import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/sync/cloud_sync_client.dart';
import 'package:budget_app/core/sync/sync_engine.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A cloud that can be made unreachable, or held mid-sync with [gate].
class FakeCloud implements CloudSyncClient {
  bool unreachable = false;
  bool signedOut = false;
  Completer<void>? gate;

  @override
  String? get currentUserId => 'user_1';

  @override
  Future<String?> ensureAuthenticated() async {
    await gate?.future;
    if (unreachable) throw Exception('Network unreachable');
    return signedOut ? null : 'user_1';
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
  late FakeCloud cloud;
  late SyncEngine engine;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
    cloud = FakeCloud();
    engine = SyncEngine(db: db, client: cloud);
  });

  tearDown(() async {
    engine.dispose();
    await db.close();
  });

  Future<void> pumpApp(WidgetTester tester, {bool withCloud = true}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BudgetApp(
      categoryStore: CategoryStore(db),
      expenseLedger: ExpenseLedger(db),
      syncEngine: withCloud ? engine : null,
    ));
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
  }

  Finder syncStatus(String text) =>
      find.descendant(of: find.byKey(const Key('sync-status')), matching: find.textContaining(text));

  testWidgets('Settings shows the sync state live while a sync runs', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    cloud.gate = Completer<void>();
    final run = engine.sync();
    await tester.pumpAndSettle();
    expect(syncStatus('Syncing'), findsOneWidget);

    cloud.gate!.complete();
    await tester.runAsync(() => run);
    await tester.pumpAndSettle();
    expect(syncStatus('Synced'), findsOneWidget);
  });

  Future<void> syncNow(WidgetTester tester) async {
    await tester.runAsync(engine.sync);
    await tester.pumpAndSettle();
  }

  final homeIndicator = find.byKey(const Key('sync-attention'));

  testWidgets('Home shows a quiet indicator after a failed sync and clears it after a good one', (tester) async {
    await pumpApp(tester);
    await syncNow(tester);
    expect(homeIndicator, findsNothing);

    cloud.unreachable = true;
    await syncNow(tester);
    expect(homeIndicator, findsOneWidget);
    expect(find.textContaining('saved on this phone'), findsOneWidget);

    cloud.unreachable = false;
    await syncNow(tester);
    expect(homeIndicator, findsNothing);
  });

  testWidgets('Home shows the indicator while offline', (tester) async {
    await pumpApp(tester);
    cloud.signedOut = true;
    await syncNow(tester);

    expect(homeIndicator, findsOneWidget);
    expect(find.textContaining('Offline'), findsOneWidget);
  });

  testWidgets('without Supabase, Settings says data is kept on this phone only and Home shows no indicator', (tester) async {
    await pumpApp(tester, withCloud: false);
    expect(homeIndicator, findsNothing);

    await openSettings(tester);
    expect(syncStatus('Not connected'), findsOneWidget);
    expect(syncStatus('kept on this phone only'), findsOneWidget);
    expect(find.byKey(const Key('sync-now-btn')), findsNothing);
  });
}
