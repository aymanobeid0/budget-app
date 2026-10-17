# 04: Adding an entry feels responsive

**Status:** resolved
**Blocked by:** none

Saving an Expense or Income from the Add sheet gives a light haptic tap, and the new entry animates into the list on Home or Income rather than popping in. Keep it subtle and fast (under 300 ms), respect the platform's reduced-motion setting (`MediaQuery.disableAnimations`), and keep existing widget tests passing.

- [x] Saving from the Add sheet triggers `HapticFeedback.lightImpact`
- [x] New Expenses and Income animate into their lists; deletes animate out
- [x] Animations are skipped when the platform asks for reduced motion
