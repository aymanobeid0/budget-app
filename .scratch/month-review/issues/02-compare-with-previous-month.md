# 02: Compare With the Previous Month

**What to build:** The blue card adds one line comparing the chosen month's spending with the month before: "X more than <month>", "X less than <month>" or "Same as <month>", in the configured Currency. It's hidden when the month before has no Expenses. On the current month it compares the month so far with the whole previous month.

**Blocked by:** 01: Step Between Months on Home

**Status:** ready-for-agent

- [ ] Month summary returns the previous month's total next to the chosen month's
- [ ] Comparison line reads more, less or same, in the configured Currency
- [ ] Hidden when the previous month has no non-deleted Expenses
- [ ] Unit tests: more, less, same, an empty previous month, and the December to January boundary
