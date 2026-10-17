import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../income.dart';
import '../income_ledger.dart';
import 'income_state.dart';

/// Income tab state, read from the Income Ledger.
class IncomeCubit extends Cubit<IncomeState> {
  IncomeCubit(this._ledger) : super(const IncomeInitial());

  final IncomeLedger _ledger;

  Future<void> load() async {
    if (isClosed) return;
    emit(const IncomeLoading());
    await _refresh();
  }

  Future<void> addIncome({
    required int amountMinor,
    required String sourceId,
    required DateTime paidOn,
  }) async {
    final now = DateTime.now();
    await _guard(() => _ledger.logIncome(Income(
          id: _generateId(),
          amountMinor: amountMinor,
          sourceId: sourceId,
          paidOn: paidOn,
          createdAt: now,
          updatedAt: now,
        )));
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!isClosed) emit(IncomeError(e.toString()));
      return;
    }
    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      final sources = await _ledger.loadSources();
      final income = await _ledger.loadIncome();
      if (!isClosed) emit(IncomeLoaded(income: income, sources: sources));
    } catch (e) {
      if (!isClosed) emit(IncomeError(e.toString()));
    }
  }

  String _generateId() {
    final rand = Random();
    const chars = '0123456789abcdef';
    final buffer = StringBuffer('inc_');
    for (var i = 0; i < 16; i++) {
      buffer.write(chars[rand.nextInt(chars.length)]);
    }
    return buffer.toString();
  }
}
