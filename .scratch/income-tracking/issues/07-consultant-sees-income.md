# 07: Consultant Sees Income

**What to build:** When I ask the Expense Consultant something like "can I afford a new phone?" or "how did my clinic income do this month?", its answer accounts for my Income: totals by Income Source, recent Income, and this month's Net.

**Blocked by:** 05: Net on Home

**Status:** ready-for-agent

- [ ] Consultant context includes an income section: totals by source, recent Income, this month's Net (reusing the Net calculation)
- [ ] With no Income logged, the section says so and the consultant still works
- [ ] Tests: spending context builder test extended for the income section and the empty case
