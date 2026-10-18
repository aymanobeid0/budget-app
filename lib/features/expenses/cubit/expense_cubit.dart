import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ids.dart';

import '../expense.dart';
import '../expense_ledger.dart';
import 'expense_state.dart';

/// The [ExpenseCubit] above [context], or null when the app runs without the
/// expenses feature (screens shared with income, tests).
ExpenseCubit? maybeExpenseCubit(BuildContext context) {
  try {
    return context.read<ExpenseCubit>();
  } catch (_) {
    return null;
  }
}

class ExpenseCubit extends Cubit<ExpenseState> {
  ExpenseCubit(this._ledger) : super(const ExpenseInitial());

  final ExpenseLedger _ledger;

  Future<void> load() async {
    if (isClosed) return;
    emit(const ExpenseLoading());
    try {
      final expenses = await _ledger.loadExpenses();
      if (isClosed) return;
      emit(ExpenseLoaded(expenses));
    } catch (e) {
      if (isClosed) return;
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> addExpense({
    required int amountMinor,
    required String categoryId,
    required DateTime spentOn,
  }) async {
    try {
      final id = randomId('exp_');
      final now = DateTime.now();
      final expense = Expense(
        id: id,
        amountMinor: amountMinor,
        categoryId: categoryId,
        spentOn: spentOn,
        createdAt: now,
        updatedAt: now,
      );
      await _ledger.logExpense(expense);
      final expenses = await _ledger.loadExpenses();
      if (isClosed) return;
      emit(ExpenseLoaded(expenses));
    } catch (e) {
      if (isClosed) return;
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      final updated = expense.copyWith(updatedAt: DateTime.now());
      await _ledger.updateExpense(updated);
      final expenses = await _ledger.loadExpenses();
      if (isClosed) return;
      emit(ExpenseLoaded(expenses));
    } catch (e) {
      if (isClosed) return;
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _ledger.deleteExpense(id);
      final expenses = await _ledger.loadExpenses();
      if (isClosed) return;
      emit(ExpenseLoaded(expenses));
    } catch (e) {
      if (isClosed) return;
      emit(ExpenseError(e.toString()));
    }
  }
}
