# 03: Expense Logging & Instant Add Slice

**What to build:** The core minimalist expense entry flow: numeric amount input, single-tap category selection, and date selection (defaulting to today). Logged expenses persist immediately via the `ExpenseLedger` module into local SQLite and render in a reverse-chronological list grouped by date.

**Blocked by:** 01: Project Scaffolding & Core Foundations, 02: Category Presets & Management Slice

**Status:** resolved

- [x] Prominent quick-add button opens a minimalist bottom sheet/dialog
- [x] Users can enter an amount, pick a category, and save in fewer than three taps
- [x] Date defaults to today with an optional date picker
- [x] Expenses display in reverse-chronological order grouped by day with category icons
- [x] Users can delete or edit an existing expense from the list
