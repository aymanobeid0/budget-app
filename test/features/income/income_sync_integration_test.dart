import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/sync/cloud_sync_client.dart';
import 'package:budget_app/core/sync/sync_engine.dart';
import 'package:budget_app/features/income/income.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Records what reaches the cloud, in order, and serves remote rows.
class FakeCloud implements CloudSyncClient {
  final calls = <String>[];
  final pushedSources = <Map<String, dynamic>>[];
  final pushedIncome = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> remoteSources = [];
  List<Map<String, dynamic>> remoteIncome = [];

  @override
  String? get currentUserId => 'usr_1';

  @override
  Future<String?> ensureAuthenticated() async => 'usr_1';

  @override
  Future<void> upsertCategories(List<Map<String, dynamic>> rows) async => calls.add('push categories');

  @override
  Future<void> upsertExpenses(List<Map<String, dynamic>> rows) async => calls.add('push expenses');

  @override
  Future<void> upsertIncomeSources(List<Map<String, dynamic>> rows) async {
    calls.add('push income sources');
    pushedSources.addAll(rows);
  }

  @override
  Future<void> upsertIncome(List<Map<String, dynamic>> rows) async {
    calls.add('push income');
    pushedIncome.addAll(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories() async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchExpenses() async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchIncomeSources() async => remoteSources;

  @override
  Future<List<Map<String, dynamic>>> fetchIncome() async => remoteIncome;
}

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late FakeCloud cloud;
  late SyncEngine engine;
  late IncomeLedger ledger;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    cloud = FakeCloud();
    engine = SyncEngine(db: db, client: cloud);
    // No sync engine on the ledger: each test syncs explicitly.
    ledger = IncomeLedger(db);
  });

  tearDown(() async {
    engine.dispose();
    await db.close();
  });

  Income income(String id, int minor, {String sourceId = 'src_salary'}) {
    final now = DateTime.now();
    return Income(
      id: id,
      amountMinor: minor,
      sourceId: sourceId,
      paidOn: DateTime.utc(2026, 10, 17),
      createdAt: now,
      updatedAt: now,
    );
  }

  test('pushes unsynced Income Sources before Income, under the user', () async {
    await ledger.loadSources();
    await ledger.logIncome(income('i1', 350000));

    final result = await engine.sync();

    expect(result.incomeSynced, 1);
    expect(result.incomeSourcesSynced, 3);
    expect(cloud.calls.indexOf('push income sources'), lessThan(cloud.calls.indexOf('push income')));
    expect(cloud.pushedSources.map((r) => r['name']), containsAll(<String>['Salary', 'Freelance', 'Other']));
    final row = cloud.pushedIncome.single;
    expect(row['id'], 'i1');
    expect(row['user_id'], 'usr_1');
    expect(row['amount_minor'], 350000);
    expect(row['source_id'], 'src_salary');
    expect(row['paid_on'], '2026-10-17');
  });

  test('synced rows are not pushed again until they change', () async {
    await ledger.loadSources();
    await ledger.logIncome(income('i1', 1000));
    await engine.sync();
    cloud.calls.clear();

    await engine.sync();
    expect(cloud.calls, isNot(contains('push income')));

    await ledger.updateIncome((await ledger.loadIncome()).single.copyWith(amountMinor: 2000));
    await engine.sync();
    expect(cloud.pushedIncome.last['amount_minor'], 2000);
  });

  test('pulls Income and Income Sources from the account', () async {
    final stamp = DateTime.utc(2026, 10, 10).toIso8601String();
    cloud.remoteSources = [
      {'id': 'src_clinic', 'name': 'Dental clinic', 'icon': 'work', 'color': 1, 'created_at': stamp, 'updated_at': stamp},
    ];
    cloud.remoteIncome = [
      {
        'id': 'i9', 'amount_minor': 42000, 'source_id': 'src_clinic', 'paid_on': '2026-10-10',
        'created_at': stamp, 'updated_at': stamp,
      },
    ];

    await engine.sync();

    expect((await ledger.loadSources()).map((s) => s.name), ['Dental clinic']);
    final pulled = (await ledger.loadIncome()).single;
    expect(pulled.amountMinor, 42000);
    expect(pulled.paidOn, DateTime.utc(2026, 10, 10));
  });

  test('soft deletes travel both ways', () async {
    await ledger.loadSources();
    await ledger.logIncome(income('i1', 1000));
    await ledger.logIncome(income('i2', 2000));
    await engine.sync();

    // Deleted here → pushed with a deleted date.
    await ledger.deleteIncome('i1');
    await ledger.deleteSource('src_other');
    await engine.sync();
    expect(cloud.pushedIncome.lastWhere((r) => r['id'] == 'i1')['deleted_at'], isNotNull);
    expect(cloud.pushedSources.lastWhere((r) => r['id'] == 'src_other')['deleted_at'], isNotNull);

    // Deleted on another phone → gone here.
    final later = DateTime.now().toUtc().add(const Duration(minutes: 1)).toIso8601String();
    cloud.remoteIncome = [
      {
        'id': 'i2', 'amount_minor': 2000, 'source_id': 'src_salary', 'paid_on': '2026-10-17',
        'created_at': later, 'updated_at': later, 'deleted_at': later,
      },
    ];
    await engine.sync();
    expect(await ledger.loadIncome(), isEmpty);
  });
}
