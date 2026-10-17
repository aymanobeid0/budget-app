# 05: Net on Home

**What to build:** Home shows my Net (Income minus Expenses) with a switch for this week, this month and all time. It opens on this month the first time, then on whatever period I last picked. Weeks start on Monday. A negative Net looks clearly different from a positive one, and the number updates as soon as I add, edit or delete an Income or Expense.

**Blocked by:** 02: Log Your First Income

**Status:** resolved

- [x] Net card on Home with week / month / all-time switch, in the configured Currency
- [x] Last chosen period is remembered on the device; default is month
- [x] Week runs Monday to Sunday; month is the calendar month
- [x] Negative Net is visually distinct
- [x] Net reacts live to changes in either ledger
- [x] Tests: Net calculation as plain unit tests with fixed "today" dates covering Monday week boundaries, month boundaries, all time, negative Net and deleted entries

## Answer

Pure `calculateNet` in `lib/features/income/net.dart` with `netWeekStart = DateTime.monday` (the user chose Monday on 2026-10-17). `NetCard` on Home sits under the spent card, with a week / month / all-time switch. `NetPeriodCubit` stores the pick in `net_period.txt` next to the other local prefs (default month). A negative Net is red with a trending-down icon; a positive Net is green with a plus sign.
