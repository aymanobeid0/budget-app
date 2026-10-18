# 02: Compare With the Previous Month

**What to build:** The blue card adds one line comparing the chosen month's spending with the month before: "X more than <month>", "X less than <month>" or "Same as <month>", in the configured Currency. It's hidden when the month before has no Expenses. On the current month it compares the month so far with the whole previous month.

**Blocked by:** 01: Step Between Months on Home

**Status:** resolved

- [x] Month summary returns the previous month's total next to the chosen month's
- [x] Comparison line reads more, less or same, in the configured Currency
- [x] Hidden when the previous month has no non-deleted Expenses
- [x] Unit tests: more, less, same, an empty previous month, and the December to January boundary

## Answer

`summarizeMonthSpending` in `lib/features/expenses/month_spending.dart` is a pure function, like `calculateNet`. Given Expenses and a `CalendarMonth`, it returns a `MonthSpending` with the month's total and the previous month's total, leaving out deleted Expenses. `compareWithPreviousMonth` turns that into "800 MRU more than September", "… less than …" or "Same as September" in the configured Currency, or null when the month before has no Expenses. It names the previous month with `CalendarMonth.label`, so January says "December 2025". The blue card on Home shows the line under its total. On the current month that compares the month so far with the whole previous month. Unit tests are in `test/features/expenses/month_spending_test.dart`, and a Home widget test steps through more, less and hidden.
