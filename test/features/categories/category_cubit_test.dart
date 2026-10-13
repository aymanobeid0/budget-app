import 'package:bloc_test/bloc_test.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/categories/cubit/category_cubit.dart';
import 'package:budget_app/features/categories/cubit/category_state.dart';
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

  blocTest<CategoryCubit, CategoryState>(
    'emits [CategoryLoading, CategoryLoaded] when load() is called',
    build: () => CategoryCubit(store),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<CategoryLoading>(),
      isA<CategoryLoaded>().having((s) => s.categories.length, 'count', greaterThanOrEqualTo(6)),
    ],
  );

  blocTest<CategoryCubit, CategoryState>(
    'adds a custom category and updates state',
    build: () => CategoryCubit(store),
    seed: () => CategoryLoaded(const []),
    act: (cubit) => cubit.addCategory(name: 'Investments', icon: 'trending_up', color: 0xFF2E7D32),
    expect: () => [
      isA<CategoryLoaded>().having(
        (s) => s.categories.any((c) => c.name == 'Investments'),
        'has Investments',
        isTrue,
      ),
    ],
  );

  blocTest<CategoryCubit, CategoryState>(
    'deletes a category and updates state',
    build: () => CategoryCubit(store),
    act: (cubit) async {
      await cubit.load();
      await cubit.addCategory(name: 'Disposable', icon: 'receipt', color: 0xFF000000);
      final added = (cubit.state as CategoryLoaded).categories.firstWhere((c) => c.name == 'Disposable');
      await cubit.deleteCategory(added.id);
    },
    verify: (cubit) {
      final state = cubit.state as CategoryLoaded;
      expect(state.categories.any((c) => c.name == 'Disposable'), isFalse);
    },
  );
}
