import 'package:flutter_bloc/flutter_bloc.dart';

import 'calendar_month.dart';

/// The month Home and the Income tab show, shared by both tabs.
///
/// Not saved: every launch opens on the current month. It never steps past
/// the current month; how far back it may go depends on the entries, so the
/// caller passes the earliest month.
class ChosenMonthCubit extends Cubit<CalendarMonth> {
  ChosenMonthCubit({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(CalendarMonth.of((clock ?? DateTime.now)()));

  final DateTime Function() _clock;

  /// Now, by the clock this cubit was given.
  DateTime get today => _clock();

  CalendarMonth get current => CalendarMonth.of(today);

  bool get isCurrent => state == current;

  /// Whether there's a month to step back to, given the [earliest] month
  /// that has an entry (null when there are none).
  bool canGoBack(CalendarMonth? earliest) => earliest != null && state.isAfter(earliest);

  bool get canGoForward => state.isBefore(current);

  void previous(CalendarMonth? earliest) {
    if (canGoBack(earliest)) emit(state.previous);
  }

  void next() {
    if (canGoForward) emit(state.next);
  }

  void showCurrent() {
    if (!isCurrent) emit(current);
  }
}
