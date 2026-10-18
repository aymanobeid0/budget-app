import 'package:equatable/equatable.dart';

import '../category.dart';

sealed class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

final class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

final class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

final class CategoryLoaded extends CategoryState {
  const CategoryLoaded(this.categories, {this.categoryById = const {}});

  /// Categories offered in pickers.
  final List<Category> categories;

  /// Every Category by id, deleted ones included, for showing where past
  /// Expenses went.
  final Map<String, Category> categoryById;

  @override
  List<Object?> get props => [categories, categoryById];
}

final class CategoryError extends CategoryState {
  const CategoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
