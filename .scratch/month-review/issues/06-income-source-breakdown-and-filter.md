# 06: Income Source Breakdown and Filter

**What to build:** Tapping the Income total card opens the breakdown sheet from 03, grouped by Income Source: the chosen month's total per source, largest first, with icon, colour and share. Income from a deleted Income Source still shows under that source's name. Tapping a row filters the Income list, with the same chip and × to clear it.

**Blocked by:** 03: Category Breakdown and Filter, 05: Step Between Months on the Income Tab

**Status:** resolved

- [x] Breakdown by Income Source, using the same pure function or a thin variant
- [x] Deleted Income Sources resolve by id (`loadSources(includeDeleted: true)`)
- [x] Same filter chip behaviour as 03
- [x] Unit test for the breakdown; widget test: open the sheet, filter, clear

## Answer

`incomeSourceBreakdown` in `lib/features/income/income_breakdown.dart` is a thin variant of 03's `monthBreakdown`: it groups the month's Income by Income Source and resolves each source through `IncomeLoaded.sourceById`, which the Income Cubit fills from `loadSources(includeDeleted: true)`, so a deleted source keeps its name, icon and colour. `incomeSourceGroup` gives a source's `BreakdownGroup`, falling back to "Unknown source" as the rows do. Tapping the Income total card opens `showBreakdownSheet` titled "Income in <month>". Picking a row filters the list and shows a `GroupFilterChip` under the card. As on Home, the filter lives in `IncomeScreen` state and stays when you change month, and the total card still shows the whole month. A filtered month with nothing in it shows "No <Income Source> Income in <month>" under the chip.
