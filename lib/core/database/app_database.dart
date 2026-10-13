import 'package:sqflite/sqflite.dart';

/// Local SQLite store: the offline-first source of truth on device.
///
/// Feature modules (`ExpenseLedger`, `CategoryStore`) own their queries;
/// this module only owns opening the file and the schema.
class AppDatabase {
  AppDatabase._(this.raw);

  static const _version = 1;

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
    await batch.commit(noResult: true);
  }

  Future<void> close() => raw.close();
}
