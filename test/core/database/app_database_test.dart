import 'package:budget_app/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() => db.close());

  Future<Set<String>> columnsOf(String table) async {
    final rows = await db.raw.rawQuery('PRAGMA table_info($table)');
    return rows.map((r) => r['name'] as String).toSet();
  }

  test('creates the categories table with sync columns', () async {
    expect(
      await columnsOf('categories'),
      containsAll(<String>[
        'id', 'name', 'icon', 'color',
        'created_at', 'updated_at', 'deleted_at', 'synced_at',
      ]),
    );
  });

  test('creates the expenses table holding amount, category and date', () async {
    expect(
      await columnsOf('expenses'),
      containsAll(<String>[
        'id', 'amount_minor', 'category_id', 'spent_on',
        'created_at', 'updated_at', 'deleted_at', 'synced_at',
      ]),
    );
  });

  test('rejects non-positive expense amounts', () async {
    await db.raw.insert('categories', {
      'id': 'c1', 'name': 'Food', 'icon': 'restaurant', 'color': 0,
      'created_at': 0, 'updated_at': 0,
    });
    expect(
      () => db.raw.insert('expenses', {
        'id': 'e1', 'amount_minor': 0, 'category_id': 'c1',
        'spent_on': '2026-10-13', 'created_at': 0, 'updated_at': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}
