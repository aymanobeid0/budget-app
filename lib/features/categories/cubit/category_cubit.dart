import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../category.dart';
import '../category_store.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(this._store) : super(const CategoryInitial());

  final CategoryStore _store;

  Future<void> load() async {
    if (isClosed) return;
    emit(const CategoryLoading());
    try {
      final categories = await _store.loadCategories();
      if (isClosed) return;
      emit(CategoryLoaded(categories));
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
      final id = _generateId();
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
      final categories = await _store.loadCategories();
      if (isClosed) return;
      emit(CategoryLoaded(categories));
    } catch (e) {
      if (isClosed) return;
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      final updated = category.copyWith(updatedAt: DateTime.now());
      await _store.saveCategory(updated);
      final categories = await _store.loadCategories();
      if (isClosed) return;
      emit(CategoryLoaded(categories));
    } catch (e) {
      if (isClosed) return;
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _store.deleteCategory(id);
      final categories = await _store.loadCategories();
      if (isClosed) return;
      emit(CategoryLoaded(categories));
    } catch (e) {
      if (isClosed) return;
      emit(CategoryError(e.toString()));
    }
  }

  String _generateId() {
    final rand = Random();
    final chars = '0123456789abcdef';
    final buffer = StringBuffer('cat_');
    for (var i = 0; i < 16; i++) {
      buffer.write(chars[rand.nextInt(chars.length)]);
    }
    return buffer.toString();
  }
}
