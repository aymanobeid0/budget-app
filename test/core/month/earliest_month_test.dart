import 'package:budget_app/core/month/calendar_month.dart';
import 'package:budget_app/core/month/earliest_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('is the month of the earliest date', () {
    expect(
      earliestMonth([DateTime.utc(2026, 9, 3), DateTime.utc(2026, 2, 28), DateTime.utc(2026, 3, 1)]),
      const CalendarMonth(2026, 2),
    );
    expect(earliestMonth([DateTime.utc(2026, 1, 15), DateTime.utc(2025, 12, 31)]), const CalendarMonth(2025, 12));
  });

  test('is null with no dates', () {
    expect(earliestMonth(const []), isNull);
  });
}
