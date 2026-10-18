# 04: Net Follows the Chosen Month

**What to build:** On a past month the Net card shows that month's Income minus Expenses and hides its week / month / all-time switch. On the current month it behaves exactly as it does today, including the stored period preference.

**Blocked by:** 01: Step Between Months on Home

**Status:** resolved

- [x] Net can be computed for a given calendar month, and deleted entries never count
- [x] On a past month the card shows that month's Net with no switch
- [x] The current month is unchanged: switch shown and the stored preference respected
- [x] Net tests extended with a past month

## Answer

`calculateNetForMonth` in `lib/features/income/net.dart` gives Net for one `CalendarMonth`. It shares the summing with `calculateNet`, so deleted entries never count and dates compare as calendar days. `NetCard` now watches `ChosenMonthCubit`: on a past month it shows "Net in <month>" for that month and hides the week / month / all-time switch without touching the stored period; on the current month it is unchanged, using the cubit's clock as "today". `net_test.dart` covers a past month across a year boundary and with deleted entries, and `net_on_home_test.dart` steps back a month to see the switch go and comes forward to see the stored period return.
