import 'package:equatable/equatable.dart';

const monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// One calendar month (a year and a month), the unit Home and the Income tab
/// are browsed in.
///
/// Dates compare as calendar days, the way spent-on and paid-on dates are
/// stored, so time of day and time zone never move an entry across a month.
class CalendarMonth extends Equatable implements Comparable<CalendarMonth> {
  const CalendarMonth(this.year, this.month) : assert(month >= 1 && month <= 12);

  /// The month [date] falls in.
  CalendarMonth.of(DateTime date) : this(date.year, date.month);

  final int year;

  /// 1 (January) to 12 (December).
  final int month;

  CalendarMonth get previous => month == 1 ? CalendarMonth(year - 1, 12) : CalendarMonth(year, month - 1);

  CalendarMonth get next => month == 12 ? CalendarMonth(year + 1, 1) : CalendarMonth(year, month + 1);

  /// Whether the calendar date of [date] is in this month.
  bool contains(DateTime date) => date.year == year && date.month == month;

  bool isBefore(CalendarMonth other) => compareTo(other) < 0;

  bool isAfter(CalendarMonth other) => compareTo(other) > 0;

  /// "August", or "August 2025" when [today] is in another year.
  String label({required DateTime today}) {
    final name = monthNames[month - 1];
    return year == today.year ? name : '$name $year';
  }

  @override
  int compareTo(CalendarMonth other) => year != other.year ? year - other.year : month - other.month;

  @override
  List<Object?> get props => [year, month];

  @override
  String toString() => 'CalendarMonth($year-${month.toString().padLeft(2, '0')})';
}
