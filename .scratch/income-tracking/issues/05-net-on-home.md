# 05: Net on Home

**What to build:** Home shows my Net (Income minus Expenses) with a switch for this week, this month and all time. It opens on this month the first time, then on whatever period I last picked. Weeks start on Saturday. A negative Net looks clearly different from a positive one, and the number updates as soon as I add, edit or delete an Income or Expense.

**Blocked by:** 02: Log Your First Income

**Status:** ready-for-agent

- [ ] Net card on Home with week / month / all-time switch, in the configured Currency
- [ ] Last chosen period is remembered on the device; default is month
- [ ] Week runs Saturday to Friday; month is the calendar month
- [ ] Negative Net is visually distinct
- [ ] Net reacts live to changes in either ledger
- [ ] Tests: Net calculation as plain unit tests with fixed "today" dates covering Saturday week boundaries, month boundaries, all time, negative Net and deleted entries
