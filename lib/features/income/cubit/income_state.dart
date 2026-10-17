import 'package:equatable/equatable.dart';

import '../income.dart';
import '../income_source.dart';

abstract class IncomeState extends Equatable {
  const IncomeState();

  @override
  List<Object?> get props => [];
}

class IncomeInitial extends IncomeState {
  const IncomeInitial();
}

class IncomeLoading extends IncomeState {
  const IncomeLoading();
}

class IncomeLoaded extends IncomeState {
  const IncomeLoaded({required this.income, required this.sources});

  /// Active Income, newest first.
  final List<Income> income;

  /// Income Sources offered in the picker.
  final List<IncomeSource> sources;

  /// Income grouped by paid-on date (YYYY-MM-DD), newest day first.
  Map<String, List<Income>> get groupedByDay {
    final map = <String, List<Income>>{};
    for (final i in income) {
      map.putIfAbsent(i.paidOnIso, () => []).add(i);
    }
    return map;
  }

  @override
  List<Object?> get props => [income, sources];
}

class IncomeError extends IncomeState {
  const IncomeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
