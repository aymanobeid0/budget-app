import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/sync/sync_engine.dart';
import 'category.dart';

/// Deep module interface for Category persistence.
///
/// Hides SQLite queries, automatic default seeding, and reactive stream notifications.
class CategoryStore {
  CategoryStore(this._db, {this.syncEngine});

  final AppDatabase _db;
  final SyncEngine? syncEngine;
  final _controller = StreamController<List<Category>>.broadcast();

  static final List<Category> defaultPresets = [
    Category(
      id: 'cat_food',
      name: 'Food',
      icon: 'restaurant',
      color: 0xFFEF4444, // Red
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    Category(
      id: 'cat_transport',
      name: 'Transport',
      icon: 'directions_car',
      color: 0xFF3B82F6, // Blue
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    Category(
      id: 'cat_utilities',
      name: 'Utilities',
      icon: 'power',
      color: 0xFFF59E0B, // Amber
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    Category(
      id: 'cat_entertainment',
      name: 'Entertainment',
      icon: 'movie',
      color: 0xFF8B5CF6, // Purple
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    Category(
      id: 'cat_health',
      name: 'Health',
      icon: 'local_hospital',
      color: 0xFF10B981, // Emerald
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    Category(
      id: 'cat_shopping',
      name: 'Shopping',
      icon: 'shopping_bag',
      color: 0xFFEC4899, // Pink
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  ];

  Future<List<Category>> loadCategories() async {
    final rows = await _db.raw.query(
      'categories',
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );

    if (rows.isEmpty) {
      await _seedDefaults();
      return loadCategories();
    }

    final categories = rows.map((r) => Category.fromMap(r)).toList();
    _controller.add(categories);
    final hasUnsynced = rows.any((r) => r['synced_at'] == null);
    if (hasUnsynced) {
      unawaited(syncEngine?.sync().then((_) {}));
    }
    return categories;
  }

  Stream<List<Category>> watchCategories() {
    // Initial fetch triggered asynchronously so listener receives cached list immediately
    loadCategories();
    return _controller.stream;
  }

  Future<void> saveCategory(Category category) async {
    await _db.raw.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadCategories();
    unawaited(syncEngine?.sync().then((_) {}));
  }

  Future<void> deleteCategory(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.raw.update(
      'categories',
      {
        'deleted_at': now,
        'updated_at': now,
        'synced_at': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadCategories();
    unawaited(syncEngine?.sync().then((_) {}));
  }

  Future<void> _seedDefaults() async {
    final batch = _db.raw.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final preset in defaultPresets) {
      final map = preset.toMap()
        ..['created_at'] = now
        ..['updated_at'] = now;
      batch.insert('categories', map, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    unawaited(syncEngine?.sync().then((_) {}));
  }

  void dispose() {
    _controller.close();
  }
}
