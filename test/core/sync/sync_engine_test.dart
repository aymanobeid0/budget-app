import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/sync/cloud_sync_client.dart';
import 'package:budget_app/core/sync/sync_engine.dart';
import 'package:budget_app/core/sync/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeCloudSyncClient implements CloudSyncClient {
  FakeCloudSyncClient({this.userId = 'test_user_123', this.shouldFail = false});

  final String? userId;
  final bool shouldFail;

  final List<Map<String, dynamic>> upsertedCategories = [];
  final List<Map<String, dynamic>> upsertedExpenses = [];
  List<Map<String, dynamic>> remoteCategoriesToReturn = [];
  List<Map<String, dynamic>> remoteExpensesToReturn = [];

  @override
  String? get currentUserId => userId;

  @override
  Future<String?> ensureAuthenticated() async {
    if (shouldFail) throw Exception('Network unreachable');
    return userId;
  }

  @override
  Future<void> upsertCategories(List<Map<String, dynamic>> categories) async {
    if (shouldFail) throw Exception('Failed to upsert categories');
    upsertedCategories.addAll(categories);
  }

  @override
  Future<void> upsertExpenses(List<Map<String, dynamic>> expenses) async {
    if (shouldFail) throw Exception('Failed to upsert expenses');
    upsertedExpenses.addAll(expenses);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    if (shouldFail) throw Exception('Failed to fetch categories');
    return remoteCategoriesToReturn;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    if (shouldFail) throw Exception('Failed to fetch expenses');
    return remoteExpensesToReturn;
  }
}

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late FakeCloudSyncClient fakeClient;
  late SyncEngine syncEngine;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    fakeClient = FakeCloudSyncClient();
    syncEngine = SyncEngine(db: db, client: fakeClient);
  });

  tearDown(() async {
    syncEngine.dispose();
    await db.close();
  });

  test('pushes unsynced local categories and expenses to cloud client and marks them synced', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Insert local category with synced_at == null
    await db.raw.insert('categories', {
      'id': 'cat_food',
      'name': 'Food',
      'icon': 'restaurant',
      'color': 0xFFEF4444,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
      'synced_at': null,
    });

    // Insert local expense with synced_at == null
    await db.raw.insert('expenses', {
      'id': 'exp_1',
      'amount_minor': 2500,
      'category_id': 'cat_food',
      'spent_on': '2026-10-14',
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
      'synced_at': null,
    });

    final result = await syncEngine.sync();

    expect(result.isSuccess, isTrue);
    expect(fakeClient.upsertedCategories.length, 1);
    expect(fakeClient.upsertedCategories.first['id'], 'cat_food');
    expect(fakeClient.upsertedCategories.first['user_id'], 'test_user_123');

    expect(fakeClient.upsertedExpenses.length, 1);
    expect(fakeClient.upsertedExpenses.first['id'], 'exp_1');
    expect(fakeClient.upsertedExpenses.first['user_id'], 'test_user_123');

    // Verify local SQLite rows have synced_at set
    final updatedCat = await db.raw.query('categories', where: 'id = ?', whereArgs: ['cat_food']);
    expect(updatedCat.first['synced_at'], isNotNull);

    final updatedExp = await db.raw.query('expenses', where: 'id = ?', whereArgs: ['exp_1']);
    expect(updatedExp.first['synced_at'], isNotNull);
  });

  test('pulls remote categories and expenses into local SQLite', () async {
    final remoteCatCreatedAt = '2026-10-14T10:00:00.000Z';
    final remoteExpCreatedAt = '2026-10-14T10:30:00.000Z';

    fakeClient.remoteCategoriesToReturn = [
      {
        'id': 'cat_remote_1',
        'name': 'Books',
        'icon': 'menu_book',
        'color': 0xFF10B981,
        'created_at': remoteCatCreatedAt,
        'updated_at': remoteCatCreatedAt,
        'deleted_at': null,
      }
    ];

    fakeClient.remoteExpensesToReturn = [
      {
        'id': 'exp_remote_1',
        'amount_minor': 1999,
        'category_id': 'cat_remote_1',
        'spent_on': '2026-10-14',
        'created_at': remoteExpCreatedAt,
        'updated_at': remoteExpCreatedAt,
        'deleted_at': null,
      }
    ];

    final result = await syncEngine.sync();

    expect(result.isSuccess, isTrue);

    // Verify pulled into local SQLite
    final localCats = await db.raw.query('categories', where: 'id = ?', whereArgs: ['cat_remote_1']);
    expect(localCats, isNotEmpty);
    expect(localCats.first['name'], 'Books');
    expect(localCats.first['synced_at'], isNotNull);

    final localExps = await db.raw.query('expenses', where: 'id = ?', whereArgs: ['exp_remote_1']);
    expect(localExps, isNotEmpty);
    expect(localExps.first['amount_minor'], 1999);
    expect(localExps.first['synced_at'], isNotNull);
  });

  test('handles offline/network failure gracefully, leaving local items queued for future sync', () async {
    final failingClient = FakeCloudSyncClient(shouldFail: true);
    final failingEngine = SyncEngine(db: db, client: failingClient);

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.raw.insert('categories', {
      'id': 'cat_offline',
      'name': 'Coffee',
      'icon': 'coffee',
      'color': 0xFF3B82F6,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
      'synced_at': null,
    });

    final result = await failingEngine.sync();

    expect(result.isSuccess, isFalse);
    expect(failingEngine.currentState, SyncState.error);

    // Verify local item is still marked as unsynced
    final item = await db.raw.query('categories', where: 'id = ?', whereArgs: ['cat_offline']);
    expect(item.first['synced_at'], isNull);

    failingEngine.dispose();
  });
}

