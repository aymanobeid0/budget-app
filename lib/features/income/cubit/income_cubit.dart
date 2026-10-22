import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ids.dart';
import '../income.dart';
import '../income_ledger.dart';
import '../income_source.dart';
import 'income_state.dart';

/// The [IncomeCubit] above [context], or null when the app runs without the
/// income feature (screens shared with expenses, tests).
IncomeCubit? maybeIncomeCubit(BuildContext context) {
  try {
    return context.read<IncomeCubit>();
  } catch (_) {
    return null;
  }
}

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
          id: randomId('inc_'),
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

  /// Saves a new Income Source and returns its id.
  Future<String> addSource({required String name, required String icon, required int color}) async {
    final now = DateTime.now();
    final id = randomId('src_');
    await _guard(() => _ledger.saveSource(IncomeSource(
          id: id,
          name: name,
          icon: icon,
          color: color,
          createdAt: now,
          updatedAt: now,
        )));
    return id;
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
}
