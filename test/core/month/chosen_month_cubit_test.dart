import 'package:budget_app/core/month/calendar_month.dart';
import 'package:budget_app/core/month/chosen_month_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('when the clock rolls into a new month', () {
    test('a user on the current month stays on the current month', () async {
      var now = DateTime(2026, 9, 30, 23, 50);
      final cubit = ChosenMonthCubit(clock: () => now);
      addTearDown(cubit.close);

      now = DateTime(2026, 10, 1, 0, 10);
      cubit.followClock();

      expect(cubit.state, const CalendarMonth(2026, 10));
      expect(cubit.isCurrent, isTrue);
    });

    test('a user on a past month stays on that month', () async {
      var now = DateTime(2026, 9, 30, 23, 50);
      final cubit = ChosenMonthCubit(clock: () => now);
      addTearDown(cubit.close);
      cubit.previous(const CalendarMonth(2026, 1));

      now = DateTime(2026, 10, 1, 0, 10);
      cubit.followClock();

      expect(cubit.state, const CalendarMonth(2026, 8));
    });
  });
}
