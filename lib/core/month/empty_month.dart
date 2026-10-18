import 'package:flutter/material.dart';

import '../theme/empty_state.dart';

/// The empty state for a chosen month with nothing to list, shared by Home
/// and the Income tab. [entries] names what's listed ("Expenses", "Income");
/// [filteredTo] is the name of the group the list is filtered to, if any, and
/// [filteredMessage] what to say then.
EmptyState emptyMonthState({
  required String entries,
  required String monthLabel,
  required bool isCurrent,
  String? filteredTo,
  required String filteredMessage,
}) =>
    EmptyState(
      icon: Icons.event_busy_rounded,
      title: filteredTo == null ? 'No $entries in $monthLabel' : 'No $filteredTo $entries in $monthLabel',
      message: filteredTo != null
          ? filteredMessage
          : isCurrent
              ? 'Nothing logged this month yet.'
              : 'Nothing was logged this month.',
    );
