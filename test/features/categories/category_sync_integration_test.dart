import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/sync/cloud_sync_client.dart';
import 'package:budget_app/core/sync/sync_engine.dart';
import 'package:budget_app/features/categories/category.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockCloudClient implements CloudSyncClient {
  int upsertCategoriesCalls = 0;

  @override
  String? get currentUserId => 'usr_1';

  @override
  Future<String?> ensureAuthenticated() async => 'usr_1';

  @override
  Future<void> upsertCategories(List<Map<String, dynamic>> categories) async {
    upsertCategoriesCalls++;
  }

  @override
  Future<void> upsertExpenses(List<Map<String, dynamic>> expenses) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchCategories() async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchExpenses() async => [];

  @override
  Future<void> upsertIncomeSources(List<Map<String, dynamic>> rows) async {}

  @override
  Future<void> upsertIncome(List<Map<String, dynamic>> rows) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchIncomeSources() async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchIncome() async => [];
}

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late MockCloudClient mockClient;
  late SyncEngine syncEngine;
  late CategoryStore store;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    mockClient = MockCloudClient();
    syncEngine = SyncEngine(db: db, client: mockClient);
    store = CategoryStore(db, syncEngine: syncEngine);
  });

  tearDown(() async {
    syncEngine.dispose();
    await db.close();
  });

  test('saving category triggers non-blocking sync through SyncEngine', () async {
    final cat = Category(
      id: 'cat_custom',
      name: 'Hobbies',
      icon: 'palette',
      color: 0xFF123456,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await store.saveCategory(cat);

    await syncEngine.idle(); // the save kicked a background sync

    expect(mockClient.upsertCategoriesCalls, greaterThanOrEqualTo(1));
  });
}
