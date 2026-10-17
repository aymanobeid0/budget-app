# 03: Edit and Delete Income, with Totals

**What to build:** On the Income tab I can tap an Income to change its amount, date or source, or delete it. Each day shows its total Income, and the tab shows the total for what's listed.

**Blocked by:** 02: Log Your First Income

**Status:** resolved

- [x] Editing an Income updates the list and totals immediately
- [x] Deleting an Income soft-deletes it and removes it from the list and totals
- [x] Day totals and the overall total are shown in the configured Currency
- [x] Tests: Income Ledger update and soft delete; totals ignore deleted Income

## Answer

Income Ledger gains `updateIncome` and soft `deleteIncome`. Tapping an Income opens the Add sheet in Edit Income mode, with a delete button. The Income tab shows a total card plus a total on each day header, all in the configured Currency.
