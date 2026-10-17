# 01: Move Categories into Profile

**What to build:** Prefactor the navigation so an Income tab has a slot. The bottom bar becomes Home, (Income slot), [+], Consultant, Profile, and Categories management is reached from Profile. Everything Categories does today keeps working from its new place. Until ticket 02 lands, the Income slot can stay hidden so the bar shows only working tabs.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] Categories tab is gone from the bottom bar; Profile has an entry that opens Categories management
- [x] Creating, editing and deleting a Category from Profile works exactly as before
- [x] The centre + button still opens the Add sheet from every tab
- [x] Existing categories screen and widget tests pass, updated only for the new route

## Answer

Categories moved under Profile at `/settings/categories` (bar: Home, [+], Consultant, Profile; Income slot comes in 02). Profile has a Categories row; the screen shows Back when pushed.
