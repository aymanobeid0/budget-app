import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_theme.dart';
import 'calendar_month.dart';
import 'chosen_month_cubit.dart';

/// The chosen month with previous and next arrows, used on Home and the
/// Income tab. Tapping a past month's name comes back to the current month.
///
/// [earliest] is the month of the first entry (null when there are none): the
/// previous arrow stops there.
class MonthHeader extends StatelessWidget {
  const MonthHeader({super.key, required this.earliest});

  final CalendarMonth? earliest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.watch<ChosenMonthCubit>();
    final month = cubit.state;
    final label = month.label(today: cubit.today);

    return Row(
      key: const Key('month-header'),
      children: [
        IconButton(
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: cubit.canGoBack(earliest) ? () => cubit.previous(earliest) : null,
        ),
        Expanded(
          child: Center(
            child: cubit.isCurrent
                ? Text(label, style: AppType.title.copyWith(color: scheme.onSurface))
                : Tooltip(
                    message: 'Back to ${cubit.current.label(today: cubit.today)}',
                    child: InkWell(
                      onTap: cubit.showCurrent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(label, style: AppType.title.copyWith(color: scheme.primary)),
                      ),
                    ),
                  ),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: cubit.canGoForward ? cubit.next : null,
        ),
      ],
    );
  }
}

/// Swiping horizontally over [child] steps the chosen month: right to the
/// month before, left to the month after. Wrap only the header and card, not
/// a list whose rows swipe to delete.
class MonthSwipeArea extends StatelessWidget {
  const MonthSwipeArea({super.key, required this.earliest, required this.child});

  final CalendarMonth? earliest;
  final Widget child;

  static const _minVelocity = 200.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        final cubit = context.read<ChosenMonthCubit>();
        if (v > _minVelocity) cubit.previous(earliest);
        if (v < -_minVelocity) cubit.next();
      },
      child: child,
    );
  }
}
