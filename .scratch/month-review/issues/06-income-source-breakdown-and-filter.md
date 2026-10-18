# 06: Income Source Breakdown and Filter

**What to build:** Tapping the Income total card opens the breakdown sheet from 03, grouped by Income Source: the chosen month's total per source, largest first, with icon, colour and share. Income from a deleted Income Source still shows under that source's name. Tapping a row filters the Income list, with the same chip and × to clear it.

**Blocked by:** 03: Category Breakdown and Filter, 05: Step Between Months on the Income Tab

**Status:** ready-for-agent

- [ ] Breakdown by Income Source, using the same pure function or a thin variant
- [ ] Deleted Income Sources resolve by id (`loadSources(includeDeleted: true)`)
- [ ] Same filter chip behaviour as 03
- [ ] Unit test for the breakdown; widget test: open the sheet, filter, clear
