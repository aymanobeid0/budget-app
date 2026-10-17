import 'dart:async';

import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/sync/cloud_sync_client.dart';
import 'package:budget_app/core/sync/sync_engine.dart';
import 'package:budget_app/core/sync/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeCloudSyncClient implements CloudSyncClient {
  FakeCloudSyncClient({this.userId = 'test_user_123', this.shouldFail = false});

  final String? userId;
  bool shouldFail;

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

  @override
  Future<void> upsertIncomeSources(List<Map<String, dynamic>> rows) async {}

  @override
  Future<void> upsertIncome(List<Map<String, dynamic>> rows) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchIncomeSources() async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchIncome() async => [];
}

/// A timer the test fires by hand, so backoff runs without waiting.
class FakeTimer implements Timer {
  FakeTimer(this.delay, this._callback);

  final Duration delay;
  final void Function() _callback;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

/// Records every retry timer the engine starts.
class FakeRetryTimers {
  final List<FakeTimer> started = [];

  Timer call(Duration delay, void Function() callback) {
    final timer = FakeTimer(delay, callback);
    started.add(timer);
    return timer;
  }

  List<FakeTimer> get pending => started.where((t) => t.isActive).toList();
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

  group('retry after an offline or failed sync', () {
    late FakeRetryTimers timers;
    late FakeCloudSyncClient cloud;
    late SyncEngine engine;

    setUp(() {
      timers = FakeRetryTimers();
      cloud = FakeCloudSyncClient(shouldFail: true);
      engine = SyncEngine(db: db, client: cloud, startTimer: timers.call);
    });

    tearDown(() => engine.dispose());

    Future<void> insertUnsyncedCategory() async {
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
    }

    test('an offline sync is retried and succeeds once the cloud is reachable', () async {
      await insertUnsyncedCategory();

      await engine.sync();
      expect(engine.currentState, SyncState.error);
      expect(timers.pending.single.delay, const Duration(seconds: 5));

      cloud.shouldFail = false;
      timers.pending.single.fire();
      await engine.idle();

      expect(engine.currentState, SyncState.success);
      expect(cloud.upsertedCategories.single['id'], 'cat_offline');
      expect(timers.pending, isEmpty);
    });

    test('retries back off 5s, 15s, 1 min, then every 5 min', () async {
      await engine.sync();
      for (var i = 0; i < 5; i++) {
        timers.pending.single.fire();
        await engine.idle();
      }

      expect(timers.started.map((t) => t.delay), const [
        Duration(seconds: 5),
        Duration(seconds: 15),
        Duration(minutes: 1),
        Duration(minutes: 5),
        Duration(minutes: 5),
        Duration(minutes: 5),
      ]);
    });

    test('a successful sync resets the backoff and leaves no retry timer running', () async {
      await engine.sync();
      timers.pending.single.fire();
      await engine.idle();
      expect(timers.pending.single.delay, const Duration(seconds: 15));

      cloud.shouldFail = false;
      await engine.sync(); // e.g. after a new Expense
      expect(engine.currentState, SyncState.success);
      expect(timers.pending, isEmpty);

      cloud.shouldFail = true;
      await engine.sync();
      expect(timers.pending.single.delay, const Duration(seconds: 5));
    });

    test('no retry runs while background syncs are paused, and retrying resumes after', () async {
      await engine.sync();
      engine.paused = true; // an account switch starts
      expect(timers.pending, isEmpty);

      // The switch's own forced sync fails too: still no retry while paused.
      await engine.sync(force: true);
      expect(timers.pending, isEmpty);

      cloud.shouldFail = false;
      engine.paused = false;
      expect(timers.pending, hasLength(1));
      timers.pending.single.fire();
      await engine.idle();
      expect(engine.currentState, SyncState.success);
    });
  });
}
