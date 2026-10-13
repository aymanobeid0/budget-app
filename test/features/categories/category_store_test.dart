import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/categories/category.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late CategoryStore store;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    store = CategoryStore(db);
  });

  tearDown(() => db.close());

  test('seeds default category presets on first load if empty', () async {
    final categories = await store.loadCategories();
    expect(categories.length, greaterThanOrEqualTo(6));
    final names = categories.map((c) => c.name).toSet();
    expect(names, containsAll(<String>[
      'Food',
      'Transport',
      'Utilities',
      'Entertainment',
      'Health',
      'Shopping',
    ]));
  });

  test('creates and loads custom category', () async {
    await store.loadCategories(); // seed defaults first
    final custom = Category(
      id: 'custom_gym',
      name: 'Gym & Fitness',
      icon: 'fitness_center',
      color: 0xFF4CAF50,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await store.saveCategory(custom);
    final categories = await store.loadCategories();
    expect(categories.any((c) => c.id == 'custom_gym' && c.name == 'Gym & Fitness'), isTrue);
  });

  test('updates an existing category', () async {
    await store.loadCategories();
    final custom = Category(
      id: 'custom_gym',
      name: 'Gym',
      icon: 'fitness_center',
      color: 0xFF4CAF50,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await store.saveCategory(custom);

    final updated = custom.copyWith(name: 'Crossfit Gym');
    await store.saveCategory(updated);

    final categories = await store.loadCategories();
    final found = categories.firstWhere((c) => c.id == 'custom_gym');
    expect(found.name, equals('Crossfit Gym'));
  });

  test('deletes a custom category', () async {
    await store.loadCategories();
    final custom = Category(
      id: 'to_delete',
      name: 'Temporary',
      icon: 'delete',
      color: 0xFF9E9E9E,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await store.saveCategory(custom);

    await store.deleteCategory('to_delete');
    final categories = await store.loadCategories();
    expect(categories.any((c) => c.id == 'to_delete'), isFalse);
  });

  test('watchCategories emits updated list whenever a category is added', () async {
    final stream = store.watchCategories();
    expectLater(
      stream,
      emitsInOrder([
        hasLength(greaterThanOrEqualTo(6)), // initial seeded
        hasLength(greaterThanOrEqualTo(7)), // after addition
      ]),
    );

    // Give stream listener a tick to attach
    await pumpEventQueue();
    await store.saveCategory(Category(
      id: 'streaming_cat',
      name: 'Hobbies',
      icon: 'palette',
      color: 0xFFE91E63,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });
}
