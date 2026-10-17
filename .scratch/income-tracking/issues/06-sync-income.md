# 06: Sync Income to Your Account

**What to build:** My Income and Income Sources sync to my Supabase account like Expenses and Categories: they save offline first, push in the background, and come back after a reinstall or on another login. Guest data moves into a new account, and switching accounts never mixes Income between accounts.

**Blocked by:** 02: Log Your First Income

**Status:** ready-for-agent

- [ ] New Supabase migration adds Income Source and Income tables mirroring categories and expenses, per-user with matching row-level security
- [ ] Sync Engine pushes and pulls Income Sources before Income; edits and soft deletes propagate
- [ ] Guest-to-account migration and account switching include Income and Income Sources
- [ ] Tests: sync integration test with a fake cloud client, like the existing expense and category sync tests
