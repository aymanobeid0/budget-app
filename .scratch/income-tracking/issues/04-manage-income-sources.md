# 04: Manage Income Sources in Profile

**What to build:** From Profile, next to Categories, I can create an Income Source (name, icon, colour, e.g. "Dental clinic"), rename it, change its look, or delete it. Deleting a source removes it from the picker but keeps its past Income, which still shows the source's name and icon and still counts.

**Blocked by:** 02: Log Your First Income

**Status:** resolved

- [x] Income Sources screen reachable from Profile, styled like Categories
- [x] Create, rename, recolour and change icon of an Income Source; changes show in the Add sheet picker
- [x] Deleting a source soft-deletes it: hidden from picker and list, past Income keeps showing it
- [x] Income Sources and Categories never appear in each other's lists
- [x] Tests: Income Ledger source create/update/soft delete; deleted source still resolves by id for past Income

## Answer

Income Sources screen at `/settings/income-sources`, reached from a Profile row next to Categories. It reuses the category form (now takes a `noun`). The Income Ledger gains `saveSource`, soft `deleteSource` and `loadSources(includeDeleted:)`, so past Income keeps showing a deleted source. Also fixed in passing: the Categories and Income Sources form sheets now open above the nav bar (it covered their Save button), and the sheet title no longer overflows.
