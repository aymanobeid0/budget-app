# 06: Sync Income to Your Account

**What to build:** My Income and Income Sources sync to my Supabase account like Expenses and Categories: they save offline first, push in the background, and come back after a reinstall or on another login. Guest data moves into a new account, and switching accounts never mixes Income between accounts.

**Blocked by:** 02: Log Your First Income

**Status:** resolved

- [x] New Supabase migration adds Income Source and Income tables mirroring categories and expenses, per-user with matching row-level security
- [x] Sync Engine pushes and pulls Income Sources before Income; edits and soft deletes propagate
- [x] Guest-to-account migration and account switching include Income and Income Sources
- [x] Tests: sync integration test with a fake cloud client, like the existing expense and category sync tests

## Answer

Migration `supabase/migrations/20261017000000_income.sql` (written, not applied): `income_sources` and `income` with per-user `(user_id, id)` keys, a per-user foreign key to the source, and RLS. `CloudSyncClient` gains income push/fetch. `SyncEngine` now pushes and pulls every table through one table-driven `_push`/`_pull`, in the order categories, expenses, income sources, income. `AccountService` includes the income tables when it marks rows for upload (guest to account) and when it clears the phone (switch or sign-out).
