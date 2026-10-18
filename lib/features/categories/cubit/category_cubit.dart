import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ids.dart';

import '../category.dart';
import '../category_store.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(this._store) : super(const CategoryInitial());

  final CategoryStore _store;

  Future<CategoryLoaded> _loaded() async {
    final all = await _store.loadAllCategories();
    return CategoryLoaded(
      [for (final c in all) if (c.deletedAt == null) c],
      categoryById: {for (final c in all) c.id: c},
    );
  }

  Future<void> load() async {
    if (isClosed) return;
    emit(const CategoryLoading());
    try {
      final loaded = await _loaded();
      if (isClosed) return;
      emit(loaded);
    } catch (e) {
      if (isClosed) return;
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> addCategory({
    required String name,
    required String icon,
    required int color,
  }) async {
    try {
      final id = randomId('cat_');
      final now = DateTime.now();
      final category = Category(
        id: id,
        name: name,
        icon: icon,
        color: color,
        createdAt: now,
        updatedAt: now,
      );
      await _store.saveCategory(category);
      final loaded = await _loaded();
      if (isClosed) return;
      emit(loaded);
    } catch (e) {
      if (isClosed) return;
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      final updated = category.copyWith(updatedAt: DateTime.now());
      await _store.saveCategory(updated);
      final loaded = await _loaded();
      if (isClosed) return;
      emit(loaded);
    } catch (e) {
      if (isClosed) return;
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _store.deleteCategory(id);
      final loaded = await _loaded();
      if (isClosed) return;
      emit(loaded);
    } catch (e) {
      if (isClosed) return;
      emit(CategoryError(e.toString()));
    }
  }
}
