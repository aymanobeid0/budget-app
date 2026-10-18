# 03: Category Breakdown and Filter

**What to build:** Tapping the blue card opens a bottom sheet listing the chosen month's total for each Category, largest first, with its icon, colour and share of the month. Expenses in a deleted Category still count under that Category's name, so the rows add up to the card's total. Tapping a row closes the sheet and filters the list to that Category. A chip above the list names the filter and has an × to clear it. The filter stays when you step to another month.

**Blocked by:** 01: Step Between Months on Home

**Status:** ready-for-agent

- [ ] Pure breakdown function: group by Category, total, share, sorted largest first with ties by name, deleted Expenses excluded
- [ ] Deleted Categories still resolve by id for name, icon and colour
- [ ] A reusable breakdown sheet widget fed by rows (03 and 06 both use it)
- [ ] The filter chip clears with ×, survives month stepping, and a filtered empty month shows the empty state with the chip
- [ ] Unit tests for the breakdown; widget test: open the sheet, tap a Category, see the filtered list and chip, clear it
