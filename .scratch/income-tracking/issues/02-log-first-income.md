# 02: Log Your First Income

**What to build:** The tracer bullet for Income. I flip the Add sheet to Income, type the amount I was paid, pick an Income Source, pick a date (default today), save, and see it on a new Income tab listed newest first, grouped by day, with the source's icon. The app starts with Salary, Freelance and Other as Income Sources. Works fully offline; no sync yet.

Covers the local database upgrade to a new version with Income and Income Source tables, a new Income Ledger deep module in its own feature slice (ADR 0004, ADR 0006), the Expense / Income switch on the Add sheet, and the Income tab in the slot from ticket 01. Use glossary terms Income and Income Source throughout.

**Blocked by:** 01: Move Categories into Profile

**Status:** ready-for-agent

- [ ] Upgrading an existing install keeps all Expenses and Categories and adds empty income tables; fresh installs create everything
- [ ] Income Ledger can log, load and watch Income, and load Income Sources; preset sources seed only on an empty table and respect the "can seed defaults" guard
- [ ] Add sheet has an Expense / Income switch; Income mode shows an Income Source picker instead of Categories, and opens on the last mode used
- [ ] Income can't be saved without an amount above zero and an Income Source
- [ ] Income tab lists Income newest first, grouped by day, with source icons
- [ ] Tests: Income Ledger against in-memory SQLite; database upgrade test from version 1; widget test of the Add sheet switch logging an Income
