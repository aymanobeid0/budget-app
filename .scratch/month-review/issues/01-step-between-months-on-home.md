# 01: Step Between Months on Home

**What to build:** Home shows one month at a time. A month header with previous and next arrows sits above the blue card, and a horizontal swipe on the header and card changes month too. The blue card and the list show only the chosen month's Expenses. Today and this week appear on the card only for the current month. The app opens on the current month and can step back to the month of the first entry, but not past the current month. Tapping the month label on a past month jumps back to the current month.

**Blocked by:** none

**Status:** resolved

- [x] Calendar month value (previous, next, contains, label with the year when it isn't the current year) with unit tests across a year boundary
- [x] Chosen-month cubit provided above both tabs in `lib/main.dart`; it isn't saved and always starts on the current month
- [x] Earliest month comes from the earliest non-deleted Expense or Income; arrows are disabled at both ends and when there are no entries
- [x] The blue card total and the list are scoped to the chosen month; today and this week show only on the current month
- [x] Empty state for a month with no Expenses
- [x] Swiping the header or card changes month and doesn't interfere with swipe-to-delete on rows
- [x] Widget test: step back a month and see that month's total and Expenses only

## Answer

The month value and the chosen month live in `lib/core/month/`, since both Home and the Income tab use them. `CalendarMonth` (`calendar_month.dart`) handles previous, next, contains and the label, which adds the year outside the current year. `ChosenMonthCubit` (`chosen_month_cubit.dart`) isn't saved and takes an optional clock for tests. It's built in `lib/main.dart` and provided above both tabs in `lib/app.dart`. `MonthHeader` and `MonthSwipeArea` (`month_header.dart`) take the earliest month and are ready for the Income tab. `earliestEntryMonth` in `lib/features/income/earliest_month.dart` finds the bound from non-deleted Expenses and Income, sitting beside `calculateNet`. On Home (`expenses_screen.dart`), the swipe area covers the header and blue card only, so swipe-to-delete on rows still works. The card and list are scoped to the chosen month, and a month with no Expenses gets its own "No Expenses in <month>" empty state.
