# 07: Consultant Sees Income

**What to build:** When I ask the Expense Consultant something like "can I afford a new phone?" or "how did my clinic income do this month?", its answer accounts for my Income: totals by Income Source, recent Income, and this month's Net.

**Blocked by:** 05: Net on Home

**Status:** resolved

- [x] Consultant context includes an income section: totals by source, recent Income, this month's Net (reusing the Net calculation)
- [x] With no Income logged, the section says so and the consultant still works
- [x] Tests: spending context builder test extended for the income section and the empty case

## Answer

`SpendingContextBuilder.build` takes optional Income, Income Sources (deleted ones included, for names) and `today`. It appends an `[USER INCOME SUMMARY]` section with total Income, this month's Net (from `calculateNet`), totals by source and the 10 most recent Income. With no Income it says so and leaves out the Net, so an empty income history is not read as overspending. `ConsultantCubit` takes an optional `IncomeLedger`.
