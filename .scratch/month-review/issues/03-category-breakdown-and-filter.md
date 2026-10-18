# 03: Category Breakdown and Filter

**What to build:** Tapping the blue card opens a bottom sheet listing the chosen month's total for each Category, largest first, with its icon, colour and share of the month. Expenses in a deleted Category still count under that Category's name, so the rows add up to the card's total. Tapping a row closes the sheet and filters the list to that Category. A chip above the list names the filter and has an × to clear it. The filter stays when you step to another month.

**Blocked by:** 01: Step Between Months on Home

**Status:** resolved

- [x] Pure breakdown function: group by Category, total, share, sorted largest first with ties by name, deleted Expenses excluded
- [x] Deleted Categories still resolve by id for name, icon and colour
- [x] A reusable breakdown sheet widget fed by rows (03 and 06 both use it)
- [x] The filter chip clears with ×, survives month stepping, and a filtered empty month shows the empty state with the chip
- [x] Unit tests for the breakdown; widget test: open the sheet, tap a Category, see the filtered list and chip, clear it

## Answer

The breakdown is generic, so 06 can reuse it for Income Sources. `monthBreakdown` in `lib/core/month/breakdown.dart` takes any entries plus how to read each one's date, group id, amount and deleted flag, and a `describe` callback that turns a group id into a `BreakdownGroup` (id, name, icon, colour). It returns `BreakdownRow`s with the total and the share (0 to 1), largest first, ties by name, and skips deleted entries and other months. `lib/core/month/breakdown_sheet.dart` has `showBreakdownSheet` (returns the tapped group's id), `GroupFilterChip` (the × clears the filter) and `GroupIconTile`. `CategoryStore.loadAllCategories` and `CategoryLoaded.categoryById` include deleted Categories, matching the Income Ledger's `includeDeleted`, so Home's rows and breakdown keep a deleted Category's name, icon and colour. The filter lives in `ExpensesScreen` state, so it stays when you change month. The blue card still shows the whole month while a filter is on, and a filtered month with nothing in it shows "No <Category> Expenses in <month>" under the chip.
