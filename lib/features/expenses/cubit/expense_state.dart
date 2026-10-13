import 'package:equatable/equatable.dart';

import '../expense.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

class ExpenseLoaded extends ExpenseState {
  const ExpenseLoaded(this.expenses);

  final List<Expense> expenses;

  /// Total sum across all loaded expenses in minor units.
  int get totalMinor => expenses.fold(0, (sum, e) => sum + e.amountMinor);

  /// Total sum formatted as standard decimal amount.
  double get totalAmount => totalMinor / 100.0;

  /// Returns expenses grouped by their ISO date (YYYY-MM-DD), maintaining
  /// reverse-chronological order.
  Map<String, List<Expense>> get groupedByDate {
    final map = <String, List<Expense>>{};
    for (final exp in expenses) {
      map.putIfAbsent(exp.spentOnIso, () => []).add(exp);
    }
    return map;
  }

  @override
  List<Object?> get props => [expenses];
}

class ExpenseError extends ExpenseState {
  const ExpenseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
