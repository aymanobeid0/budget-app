# 04: Manage Income Sources in Profile

**What to build:** From Profile, next to Categories, I can create an Income Source (name, icon, colour, e.g. "Dental clinic"), rename it, change its look, or delete it. Deleting a source removes it from the picker but keeps its past Income, which still shows the source's name and icon and still counts.

**Blocked by:** 02: Log Your First Income

**Status:** ready-for-agent

- [ ] Income Sources screen reachable from Profile, styled like Categories
- [ ] Create, rename, recolour and change icon of an Income Source; changes show in the Add sheet picker
- [ ] Deleting a source soft-deletes it: hidden from picker and list, past Income keeps showing it
- [ ] Income Sources and Categories never appear in each other's lists
- [ ] Tests: Income Ledger source create/update/soft delete; deleted source still resolves by id for past Income
