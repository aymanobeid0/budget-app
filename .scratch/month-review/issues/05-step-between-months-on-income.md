# 05: Step Between Months on the Income Tab

**What to build:** The Income tab gets the same month header, arrows and swipe as Home, driven by the same chosen month. The total card shows the chosen month's Income, and the list shows only that month's Income, still grouped by day. There's an empty state for a month with no Income.

**Blocked by:** 01: Step Between Months on Home

**Status:** resolved

- [x] Reuses the month header from 01
- [x] Total card and list scoped to the chosen month
- [x] Empty state for a month with no Income
- [x] Widget test: step back a month and see that month's Income only

## Answer

`IncomeScreen` (`lib/features/income/ui/income_screen.dart`) reuses `MonthHeader` and `MonthSwipeArea` from 01 and the shared `ChosenMonthCubit`, so both tabs show the same month. The swipe area is the header and total card only. The earliest month comes from `earliestEntryMonth` over both Expenses and Income, so an earlier Expense lets the Income tab step back to it too. `IncomeLoaded.forMonth` (`income_state.dart`) narrows the state to one month, so the total card ("Income in <month>"), the day groups and their day totals all follow the chosen month. With no Income at all the tab keeps its "No Income yet" welcome. A month with no Income shows the card at 0 and a "No Income in <month>" empty state. Widget tests are in `test/features/income/income_screen_test.dart`.
