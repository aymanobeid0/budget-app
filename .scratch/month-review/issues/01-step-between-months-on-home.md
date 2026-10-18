# 01: Step Between Months on Home

**What to build:** Home shows one month at a time. A month header with previous and next arrows sits above the blue card, and a horizontal swipe on the header and card changes month too. The blue card and the list show only the chosen month's Expenses. Today and this week appear on the card only for the current month. The app opens on the current month and can step back to the month of the first entry, but not past the current month. Tapping the month label on a past month jumps back to the current month.

**Blocked by:** none

**Status:** ready-for-agent

- [ ] Calendar month value (previous, next, contains, label with the year when it isn't the current year) with unit tests across a year boundary
- [ ] Chosen-month cubit provided above both tabs in `lib/main.dart`; it isn't saved and always starts on the current month
- [ ] Earliest month comes from the earliest non-deleted Expense or Income; arrows are disabled at both ends and when there are no entries
- [ ] The blue card total and the list are scoped to the chosen month; today and this week show only on the current month
- [ ] Empty state for a month with no Expenses
- [ ] Swiping the header or card changes month and doesn't interfere with swipe-to-delete on rows
- [ ] Widget test: step back a month and see that month's total and Expenses only
