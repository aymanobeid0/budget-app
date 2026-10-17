# Income Tracking

**Status:** ready-for-agent

## Problem Statement

The app only knows what I spend. I also receive money (a monthly salary, and a daily share of what I do at the dental clinic), and I have no way to record it. So I can't see whether I'm spending more than I make this week or this month, and the Expense Consultant can't tell me whether I can afford something.

## Solution

I can log Income the same quick way I log an Expense: I open the Add sheet, flip it to Income, type the amount I was paid, pick an Income Source (e.g. Salary, Dental clinic), and save. Income has its own tab where I see my income list and manage my Income Sources. Home shows my Net (Income minus Expenses) for this week, this month, or all time. The Expense Consultant takes my Income into account. Everything works offline and syncs to my account like Expenses.

## User Stories

1. As a user, I want to switch the Add sheet between Expense and Income, so that I log all money in one familiar place.
2. As a user, I want the Add sheet to keep the same amount pad and date picker for Income, so that logging income feels as fast as logging an expense.
3. As a user, I want to type the exact amount I was paid, so that my records match what actually reached me.
4. As a user, I want to enter my dental-clinic share as the final amount, so that I don't have to remember percentages in the app.
5. As a user, I want the date to default to today, so that logging money I just received takes as few taps as possible.
6. As a user, I want to pick a different date, so that I can log money I was paid on an earlier day.
7. As a user, I want to pick an Income Source with a single tap, so that each Income records where it came from.
8. As a user, I want to be unable to save Income without an amount above zero and an Income Source, so that I don't create broken entries.
9. As a user, I want the Add sheet to open on the mode I used last, so that it opens on Income when I'm logging several payments in a row.
10. As a user, I want the app to start with Salary, Freelance and Other as Income Sources, so that I can log my first Income immediately.
11. As a user, I want to create my own Income Source with a name, icon and colour, so that I can add "Dental clinic".
12. As a user, I want to rename an Income Source or change its icon or colour, so that my list stays meaningful.
13. As a user, I want to delete an Income Source, so that old sources stop cluttering the picker.
14. As a user, I want past Income from a deleted Income Source to stay in my history and in my Net, so that deleting a source never rewrites my past.
15. As a user, I want past Income from a deleted Income Source to still show that source's name, so that I can tell where the money came from.
16. As a user, I want Income Sources kept separate from expense Categories, so that "Food" never appears as a place money comes from.
17. As a user, I want an Income tab in the bottom bar, so that I can reach my income list in one tap.
18. As a user, I want the Income tab to list my Income newest first, grouped by day, with each source's icon, so that it reads like my expense list.
19. As a user, I want to see each day's and the visible period's total Income on the Income tab, so that I know how much I made.
20. As a user, I want to edit an Income's amount, date or source, so that I can fix mistakes.
21. As a user, I want to delete an Income, so that I can remove an entry I logged by accident.
22. As a user, I want to manage my Income Sources from the Income tab, so that sources live next to the income they group.
23. As a user, I want Home to show my Net (Income minus Expenses), so that I see at a glance whether I'm ahead or behind.
24. As a user, I want to switch the Net between this week, this month and all time, so that I can look at the period I care about.
25. As a user, I want Home to open on this month the first time, and on the period I last picked after that, so that it shows what I usually look at.
26. As a user, I want "this week" to start on Monday, so that it matches my work week.
27. As a user, I want a negative Net to look clearly different from a positive one, so that overspending stands out.
28. As a user, I want the Net to show in my configured Currency, so that it matches the rest of the app.
29. As a user, I want the Net to update immediately when I add, edit or delete an Income or Expense, so that the number is always current.
30. As a user, I want to ask the Expense Consultant "can I afford X?" and get an answer that considers my Income, so that its advice reflects my real situation.
31. As a user, I want the Expense Consultant to know my Income by source and period, so that it can spot patterns such as "your clinic income dropped this month".
32. As a user, I want logging Income to work with no internet, so that I can record a payment anywhere.
33. As a user, I want my Income and Income Sources to sync to my account, so that they come back after I reinstall or log in on another phone.
34. As a guest user, I want my Income to move into my account when I create one, so that I don't lose it, the same as my Expenses.
35. As a user switching accounts, I want each account to see only its own Income and Income Sources, so that data never mixes.
36. As a user, I want the app to never add Income on its own, so that every number is something I confirmed.

## Implementation Decisions

- **Domain vocabulary** follows GLOSSARY.md: Income, Income Source, Net. Never "transaction", "balance" or "earning". Recorded in ADR 0006.
- **Income is its own record**: id, amount in integer minor units (> 0), Income Source id, paid-on calendar date, created/updated/deleted/synced timestamps. Same shape and conventions as Expense. No note, no percentage, no fixed/dynamic flag, no recurrence (ADR 0002 and 0006).
- **Income Source** has the same shape as Category (id, name, icon, colour, timestamps, soft delete) but is a separate record type and table, never shared with Categories.
- **New deep module: Income Ledger**, in a new `income` feature slice (ADR 0004). It mirrors the Expense Ledger and Category Store in one module: load, watch, log, update and soft-delete Income; load, watch, create, update and soft-delete Income Sources; seed the three preset sources on an empty table, using the same "can seed defaults" guard Category Store uses during account downloads. Every mutation clears its synced timestamp and triggers a background sync.
- **Soft-deleted Income Sources** are excluded from pickers and the sources list, but still resolve by id so past Income can display the source's name and icon.
- **Local schema**: two new SQLite tables (income sources, income), with an index on the paid-on date. This is the first schema upgrade, so the database version goes from 1 to 2 with an upgrade step that creates the new tables, and fresh installs create everything.
- **Cloud schema**: a new Supabase migration adds income source and income tables mirroring the categories and expenses tables, scoped by user id with row-level security matching the per-user rules already in place.
- **Sync**: the Sync Engine and the cloud sync client gain push/pull for income sources (before income, as categories go before expenses), following the existing unsynced-rows and last-write-wins rules. Guest-to-account migration and account switching include the new tables.
- **Net calculation**: a pure function taking Income, Expenses, a period (week/month/all time), "today" and a week-start day (Monday), returning total income, total expenses and Net in minor units. Calendar boundaries use local calendar dates, matching how paid-on and spent-on dates are stored.
- **Net period preference** is stored locally on the device with the other local prefs; the default is month.
- **Add sheet**: the existing expense sheet gains an Expense / Income switch. In Income mode the category picker is replaced by an Income Source picker; amount pad and date picker are shared. The sheet opens on the last mode used.
- **Navigation**: Home, Income, [+], Consultant, Profile. Categories and Income Sources management move into Profile. The + button opens the Add sheet from every tab.
- **Income tab**: a screen with its own cubit reading from the Income Ledger: income list grouped by day with totals, edit and delete, and access to Income Sources management.
- **Home**: a Net card with a period switch above the existing expense list, fed by both ledgers through the Net calculation.
- **Expense Consultant**: the spending context builder also receives Income and Income Sources and adds an income section (totals by source, recent Income, Net for this month), so prompts can reason about affordability.

## Testing Decisions

- Good tests here check behaviour you can observe through a module's public interface (what you can load or watch after an action, what was pushed to the cloud), never SQL, table names or private helpers.
- **Income Ledger**: tested against an in-memory SQLite database (sqflite ffi) like the existing expense ledger and category store tests. Covers log/edit/delete, ordering, preset seeding and the no-seed guard, source soft delete keeping past Income, and that deleted sources still resolve by id.
- **Income sync**: an integration test with a fake cloud sync client, like the existing expense and category sync integration tests. Covers push of unsynced Income and sources, sources pushed before income, pull, and soft deletes propagating.
- **Database upgrade**: extend the database test to open a version-1 database with data, upgrade to version 2, and check existing Expenses and Categories survive alongside empty income tables.
- **Net calculation**: plain unit tests with fixed "today" dates covering Monday week boundaries, month boundaries, all time, negative Net, and deleted entries excluded.
- **Add sheet switch**: one widget test, like the existing expenses screen test: switch to Income, enter an amount, pick a source, save, and see the Income in the ledger.
- **Consultant context**: extend the spending context builder test to check the income section appears, and that it reads correctly with no Income.

## Out of Scope

- Recurring or automatic Income, and pre-filled amounts.
- Calculating a percentage share of clinic revenue.
- Tracking money earned but not yet paid (payouts, amounts owed).
- Notes, attachments or tags on Income.
- Budgets, savings goals, or forecasts.
- Multiple currencies or exchange rates.
- Charts or an income analytics dashboard (questions go to the Expense Consultant, per ADR 0002).

## Further Notes

- Design was settled in the grilling session on 2026-10-17; see ADR 0006 and the glossary terms Income, Income Source and Net.
- The week start is Monday (confirmed by the user on 2026-10-17, replacing the earlier Saturday recommendation); it's one constant in the Net calculation.
- This spec builds on the existing tickets in `.scratch/personal-expense-tracker/`; issue 04 (Supabase sync and anonymous auth) and issue 06 (currency and settings) are the closest prior art.
