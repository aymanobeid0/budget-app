import 'package:sqflite/sqflite.dart';

/// Local SQLite store: the offline-first source of truth on device.
///
/// Feature modules (`ExpenseLedger`, `CategoryStore`, `IncomeLedger`) own their queries;
/// this module only owns opening the file and the schema.
class AppDatabase {
  AppDatabase._(this.raw);

  static const _version = 2;

  /// Underlying handle. Only feature deep modules should touch this.
  final Database raw;

  static Future<AppDatabase> open({
    required DatabaseFactory factory,
    required String path,
  }) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createSchema,
        onUpgrade: _upgradeSchema,
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _createSchema(Database db, int version) async {
    final batch = db.batch()
      ..execute('''
        CREATE TABLE categories (
          id          TEXT PRIMARY KEY,
          name        TEXT NOT NULL,
          icon        TEXT NOT NULL,
          color       INTEGER NOT NULL,
          created_at  INTEGER NOT NULL,
          updated_at  INTEGER NOT NULL,
          deleted_at  INTEGER,
          synced_at   INTEGER
        )
      ''')
      ..execute('''
        CREATE TABLE expenses (
          id            TEXT PRIMARY KEY,
          amount_minor  INTEGER NOT NULL CHECK (amount_minor > 0),
          category_id   TEXT NOT NULL REFERENCES categories (id),
          spent_on      TEXT NOT NULL,
          created_at    INTEGER NOT NULL,
          updated_at    INTEGER NOT NULL,
          deleted_at    INTEGER,
          synced_at     INTEGER
        )
      ''')
      ..execute(
        'CREATE INDEX expenses_spent_on_idx ON expenses (spent_on DESC)',
      );
    _createIncomeTables(batch);
    await batch.commit(noResult: true);
  }

  static Future<void> _upgradeSchema(Database db, int from, int to) async {
    final batch = db.batch();
    if (from < 2) _createIncomeTables(batch);
    await batch.commit(noResult: true);
  }

  /// Version 2: Income and Income Sources (ADR 0006), kept apart from
  /// expenses and categories.
  static void _createIncomeTables(Batch batch) {
    batch
      ..execute('''
        CREATE TABLE income_sources (
          id          TEXT PRIMARY KEY,
          name        TEXT NOT NULL,
          icon        TEXT NOT NULL,
          color       INTEGER NOT NULL,
          created_at  INTEGER NOT NULL,
          updated_at  INTEGER NOT NULL,
          deleted_at  INTEGER,
          synced_at   INTEGER
        )
      ''')
      ..execute('''
        CREATE TABLE income (
          id            TEXT PRIMARY KEY,
          amount_minor  INTEGER NOT NULL CHECK (amount_minor > 0),
          source_id     TEXT NOT NULL REFERENCES income_sources (id),
          paid_on       TEXT NOT NULL,
          created_at    INTEGER NOT NULL,
          updated_at    INTEGER NOT NULL,
          deleted_at    INTEGER,
          synced_at     INTEGER
        )
      ''')
      ..execute('CREATE INDEX income_paid_on_idx ON income (paid_on DESC)');
  }

  Future<void> close() => raw.close();
}
