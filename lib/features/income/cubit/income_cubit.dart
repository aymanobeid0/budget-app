import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../income.dart';
import '../income_ledger.dart';
import '../income_source.dart';
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
          id: _generateId('inc_'),
          amountMinor: amountMinor,
          sourceId: sourceId,
          paidOn: paidOn,
          createdAt: now,
          updatedAt: now,
        )));
  }

  Future<void> updateIncome(Income income) =>
      _guard(() => _ledger.updateIncome(income.copyWith(updatedAt: DateTime.now())));

  Future<void> deleteIncome(String id) => _guard(() => _ledger.deleteIncome(id));

  Future<void> addSource({required String name, required String icon, required int color}) {
    final now = DateTime.now();
    return _guard(() => _ledger.saveSource(IncomeSource(
          id: _generateId('src_'),
          name: name,
          icon: icon,
          color: color,
          createdAt: now,
          updatedAt: now,
        )));
  }

  Future<void> updateSource(IncomeSource source) =>
      _guard(() => _ledger.saveSource(source.copyWith(updatedAt: DateTime.now())));

  Future<void> deleteSource(String id) => _guard(() => _ledger.deleteSource(id));

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
      final all = await _ledger.loadSources(includeDeleted: true);
      final income = await _ledger.loadIncome();
      if (!isClosed) {
        emit(IncomeLoaded(
          income: income,
          sources: all.where((s) => !s.isDeleted).toList(),
          sourceById: {for (final s in all) s.id: s},
        ));
      }
    } catch (e) {
      if (!isClosed) emit(IncomeError(e.toString()));
    }
  }

  String _generateId(String prefix) {
    final rand = Random();
    const chars = '0123456789abcdef';
    final buffer = StringBuffer(prefix);
    for (var i = 0; i < 16; i++) {
      buffer.write(chars[rand.nextInt(chars.length)]);
    }
    return buffer.toString();
  }
}
