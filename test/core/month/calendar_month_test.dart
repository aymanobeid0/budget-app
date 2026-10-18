import 'package:budget_app/core/month/calendar_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarMonth', () {
    test('steps back and forward across a year boundary', () {
      expect(const CalendarMonth(2026, 1).previous, const CalendarMonth(2025, 12));
      expect(const CalendarMonth(2025, 12).next, const CalendarMonth(2026, 1));
      expect(const CalendarMonth(2026, 6).previous, const CalendarMonth(2026, 5));
      expect(const CalendarMonth(2026, 6).next, const CalendarMonth(2026, 7));
    });

    test('is the month a date falls in, whatever the time of day', () {
      expect(CalendarMonth.of(DateTime(2025, 12, 31, 23, 59)), const CalendarMonth(2025, 12));
      expect(CalendarMonth.of(DateTime.utc(2026, 1, 1)), const CalendarMonth(2026, 1));
    });

    test('contains the calendar dates of its own month only', () {
      const december = CalendarMonth(2025, 12);
      expect(december.contains(DateTime(2025, 12, 1)), isTrue);
      expect(december.contains(DateTime(2025, 12, 31, 23, 59)), isTrue);
      expect(december.contains(DateTime.utc(2025, 12, 31)), isTrue);
      expect(december.contains(DateTime(2026, 1, 1)), isFalse);
      expect(december.contains(DateTime(2025, 11, 30)), isFalse);
      expect(december.contains(DateTime(2024, 12, 15)), isFalse);
    });

    test('orders months across a year boundary', () {
      expect(const CalendarMonth(2025, 12).isBefore(const CalendarMonth(2026, 1)), isTrue);
      expect(const CalendarMonth(2026, 1).isAfter(const CalendarMonth(2025, 12)), isTrue);
      expect(const CalendarMonth(2026, 1).isBefore(const CalendarMonth(2026, 1)), isFalse);
      expect(const CalendarMonth(2026, 1).isAfter(const CalendarMonth(2026, 1)), isFalse);
    });

    test('label names the month, adding the year only when it is not the current year', () {
      final today = DateTime(2026, 1, 10);
      expect(const CalendarMonth(2026, 1).label(today: today), 'January');
      expect(const CalendarMonth(2025, 12).label(today: today), 'December 2025');
      expect(const CalendarMonth(2025, 8).label(today: DateTime(2025, 12, 1)), 'August');
    });
  });
}
