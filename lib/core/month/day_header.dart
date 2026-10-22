import 'package:flutter/material.dart';
import '../format/money.dart';
import '../theme/app_theme.dart';

const _shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "20 Feb 2024": the date under an entry's title in a list row.
String shortDate(DateTime d) => '${d.day} ${_shortMonths[d.month - 1]} ${d.year}';

/// A day's heading in a month list: "Today", "Yesterday" or the date, with
/// that day's total.
class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.day, required this.today, required this.totalMinor, required this.currency});
  final DateTime day;

  /// Now, by the chosen month's clock, for "Today" and "Yesterday".
  final DateTime today;
  final int totalMinor;
  final Currency currency;

  String _label() {
    final now = this.today;
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final label = '${_weekdays[d.weekday - 1]}, ${d.day} ${_shortMonths[d.month - 1]}';
    return d.year == now.year ? label : '$label ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 22, AppSpace.gutter, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(_label(), style: AppType.caption.copyWith(color: scheme.onSurfaceVariant)),
          ),
          Text(
            Money.withLabel(totalMinor, currency),
            style: AppType.caption.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppFonts.tabular),
          ),
        ],
      ),
    );
  }
}
