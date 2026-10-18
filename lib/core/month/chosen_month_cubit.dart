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
        super(CalendarMonth.of((clock ?? DateTime.now)())) {
    _lastCurrent = state;
  }

  final DateTime Function() _clock;

  /// The current month when the clock was last checked.
  late CalendarMonth _lastCurrent;

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

  /// Re-checks the clock (the app calls this when it comes back to the
  /// foreground): if a new month has begun and the user was on the current
  /// month, moves to the new one. A past month stays put.
  void followClock() {
    final now = current;
    if (now == _lastCurrent) return;
    final wasOnCurrent = state == _lastCurrent;
    _lastCurrent = now;
    if (wasOnCurrent) emit(now);
  }
}
