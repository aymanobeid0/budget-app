# Month Review

**Status:** ready-for-agent

## Problem Statement

Home only ever tells me about this month. The blue card shows what I spent in the current month, and under it is one long list of every Expense I have ever logged, with no month breaks and no way to narrow it. The Income tab is the same: one total for everything and one long list. So I can't answer simple questions about the past, like "what did I spend in August?", "where did most of it go?" or "was I better than the month before?", without scrolling and adding things up in my head or asking the Expense Consultant. Other people using the app will hit this the first time they want to look back.

## Solution

Home and the Income tab both show one month at a time. I step to earlier months with arrows or a swipe, and the app always opens on the current month. The blue card shows the chosen month's spending and one line comparing it with the month before ("800 MRU more than September"). Tapping the blue card opens a sheet with that month's total per Category, largest first; tapping a Category closes the sheet and filters the list to it, with a chip above the list to clear the filter. The Net card follows the chosen month. On the Income tab, tapping the total opens the same kind of sheet grouped by Income Source, with the same filter. Nothing new is stored and nothing syncs differently: this is a new way to read the entries I already have.

## User Stories

1. As a user, I want Home to open on the current month, so that the first thing I see is what matters now.
2. As a user, I want to step to the previous and next month with arrows, so that I can look back one month at a time.
3. As a user, I want to swipe left and right to change month, so that stepping feels natural on a phone.
4. As a user, I want to see which month I'm looking at, with the year when it isn't the current year, so that I never confuse August 2025 with August 2026.
5. As a user, I want to be unable to step past my first entry or into future months, so that I never land on months that can only be empty.
6. As a user, I want a quick way back to the current month after stepping back, so that I don't have to tap the arrow many times.
7. As a user, I want the blue card to show what I spent in the chosen month, so that its total matches the list under it.
8. As a user, I want the today and this-week figures on the blue card to show only on the current month, so that a past month never shows "today".
9. As a user, I want the list on Home to show only the chosen month's Expenses, so that I can read one month without scrolling through all of them.
10. As a user, I want a clear empty state for a month with no Expenses, so that I know the month is empty rather than broken.
11. As a user, I want the blue card to say how the chosen month compares with the month before, so that I know whether I spent more or less.
12. As a user, I want the comparison hidden when the month before has no Expenses, so that I don't see a misleading "more than 0".
13. As a user, I want the comparison for the current month to compare the whole month so far against the whole previous month, so that the rule is simple to understand.
14. As a user, I want to tap the blue card to see the chosen month's total for each Category, largest first, so that I see where my money went.
15. As a user, I want each Category in the breakdown to show its icon, colour and share of the month, so that it reads like the rest of the app.
16. As a user, I want Expenses whose Category I deleted to still appear under that Category's name, so that the breakdown always adds up to the card's total.
17. As a user, I want to tap a Category in the breakdown to filter the month's list to that Category, so that I can see exactly what made it up.
18. As a user, I want a chip above the list showing the active Category filter, with an × to clear it, so that I always know the list is filtered.
19. As a user, I want the Category filter to stay when I step to another month, so that I can follow one Category across months.
20. As a user, I want the Net card to show the chosen month's Income minus Expenses when I'm on a past month, so that everything on Home talks about the same month.
21. As a user, I want the Net card's week / month / all-time switch to work as today when I'm on the current month, so that nothing I rely on changes.
22. As a user, I want the Income tab to step between months the same way as Home, so that both tabs behave alike.
23. As a user, I want the Income total card to show the chosen month's Income, so that it matches the list.
24. As a user, I want to tap the Income total to see the chosen month's Income per Income Source, largest first, so that I see where my money came from.
25. As a user, I want to tap an Income Source in that breakdown to filter the Income list to it, with the same clearing chip, so that the tabs work the same way.
26. As a user, I want Income from a deleted Income Source to still show under that source's name in the breakdown, so that the total still adds up.
27. As a user, I want every total and the comparison in my configured Currency, so that they match the rest of the app.
28. As a user, I want all of this to update immediately when I add, edit or delete an entry, so that the numbers are always current.
29. As a user, I want all of this to work offline, so that looking back never needs a connection.

## Implementation Decisions

- **No schema change and no sync change.** Everything is derived from what the Expense Ledger and Income Ledger already stream. No database version bump, no Supabase migration.
- **ADR 0002 stays as it is**: no budgets, caps, recurring entries, notes or charts. The breakdown is a plain list of rows. There's no free-text search (an Expense has no note or name to search), and the breakdown has no "Ask the Consultant" button (left out on 2026-10-18).
- **A calendar month value**: one small value type (year and month) with previous, next, "contains this calendar date" and a label. It sits beside the existing Net calculation in the income slice, or in `lib/core/` if both slices need it without depending on each other; pick whichever ADR 0004 favours once it's written. Dates compare as calendar days, the way `calculateNet` already does, so time of day never moves an entry across a month boundary.
- **One chosen month shared by Home and the Income tab** (confirmed by ayman on 2026-10-18). A small cubit holds it and is provided above both tabs in `lib/main.dart`. It's not saved, so every launch opens on the current month.
- **Bounds**: the earliest month you can reach is the month of the earliest non-deleted Expense or Income. With no entries, both arrows are disabled. The latest month is the current month.
- **Month summaries are pure functions** like `calculateNet`: given entries and a month, they return the month's total, the per-group breakdown (group id, total, share, sorted largest first, ties by name) and the previous month's total. One function covers Expenses by Category and Income by Income Source, or there are two thin ones. They're unit tested with fixed dates.
- **Comparison line**: "X more than <previous month>", "X less than <previous month>" or "Same as <previous month>", in the configured Currency. It's hidden when the previous month has no Expenses. For the current month it compares the month so far with the whole previous month.
- **Net card**: when the chosen month is the current month it behaves exactly as today (switch and stored period preference unchanged). On a past month it shows that month's Net and hides the switch. `calculateNet` gains a way to compute Net for a given month, or the card calls the month summary; either way deleted entries never count.
- **Breakdown sheet**: a bottom sheet opened by tapping the blue card (Home) or the Income total card (Income tab). It reuses one widget fed by rows, and resolves Category and Income Source names including soft-deleted ones (the Income Ledger already supports `includeDeleted`; Category Store needs the same if it doesn't have it).
- **Filter**: lives in screen state, not in a ledger. It survives month stepping and clears with the chip's ×. A filter whose group has no entries in the chosen month shows the empty state with the chip still visible.
- **Gestures**: a horizontal swipe on the month header and card area changes month. It mustn't fight the list rows' swipe-to-delete, so the swipe area is the header and card, not the list.
- **Domain words** follow GLOSSARY.md: Expense, Income, Category, Income Source, Net. Never "transaction" in new copy. The existing "Transactions" heading on Home may stay; renaming it is out of scope.

## Testing Decisions

- Test behaviour you can observe through a module's interface, as earlier specs do.
- **Month value and summaries**: plain unit tests with fixed dates covering month and year boundaries (December to January), deleted entries excluded, deleted groups still counted, sort order and ties, shares adding to 100%, and an empty previous month.
- **Bounds**: unit test for the earliest month (from both ledgers' entries, ignoring deleted ones) and the no-entries case.
- **Net for a month**: extend the Net tests with a past month.
- **Home widget test**, like the existing expenses screen test: step back a month and see that month's total and list, open the breakdown, tap a Category, see the filtered list and the chip, clear it.
- **Income tab widget test**: step back a month, open the Income Source breakdown, filter.

## Out of Scope

- Charts, graphs or trend lines.
- Budgets, caps or targets per Category.
- Free-text search.
- Custom date ranges, or weeks and years as browsing units.
- A Consultant shortcut from the breakdown.
- A comparison line on the Income total card.
- Changing the Expense Consultant's context.

## Further Notes

- Design was settled in a grilling session on 2026-10-18 with ayman. Decisions: browse month by month; a Category breakdown opened by tapping the blue card; a comparison with the previous month; the Net card follows the chosen month; the Income tab gets month stepping and an Income Source breakdown; no search; no Consultant button; ADR 0002 unchanged.
- Defaults picked without a question and open to change: the app opens on the current month; you can step back to the first entry but not forward past today; the filter chip has an × to clear it; the filter survives month stepping. ayman also confirmed (2026-10-18) that one chosen month is shared by both tabs.
- Tickets are in `issues/`. 01 comes first. 02, 03, 04 and 05 each depend only on 01, and 06 needs 03 and 05.
