import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/sync/cloud_sync_client.dart';
import 'package:budget_app/core/sync/sync_engine.dart';
import 'package:budget_app/features/expenses/expense.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockCloudClient implements CloudSyncClient {
  int upsertExpensesCalls = 0;

  @override
  String? get currentUserId => 'usr_1';

  @override
  Future<String?> ensureAuthenticated() async => 'usr_1';

  @override
  Future<void> upsertCategories(List<Map<String, dynamic>> categories) async {}

  @override
  Future<void> upsertExpenses(List<Map<String, dynamic>> expenses) async {
    upsertExpensesCalls++;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories() async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchExpenses() async => [];
}

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late MockCloudClient mockClient;
  late SyncEngine syncEngine;
  late ExpenseLedger ledger;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    // Insert category dependency
    await db.raw.insert('categories', {
      'id': 'cat_food',
      'name': 'Food',
      'icon': 'restaurant',
      'color': 0xFFEF4444,
      'created_at': 0,
      'updated_at': 0,
      'deleted_at': null,
      'synced_at': null,
    });
    mockClient = MockCloudClient();
    syncEngine = SyncEngine(db: db, client: mockClient);
    ledger = ExpenseLedger(db, syncEngine: syncEngine);
  });

  tearDown(() async {
    syncEngine.dispose();
    await db.close();
  });

  test('logging expense triggers non-blocking sync through SyncEngine', () async {
    final now = DateTime.now();
    final expense = Expense(
      id: 'exp_test_1',
      amountMinor: 3500,
      categoryId: 'cat_food',
      spentOn: now,
      createdAt: now,
      updatedAt: now,
    );

    await ledger.logExpense(expense);

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(mockClient.upsertExpensesCalls, greaterThanOrEqualTo(1));
  });
}
