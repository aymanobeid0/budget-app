# 05: Clear empty states everywhere

**Status:** resolved
**Blocked by:** none

Every list screen has an empty state that says what goes there and offers the next step, built on the shared `EmptyState` widget in `lib/core/theme/empty_state.dart` (currently unused). Home and Income already have their own (`_EmptyTransactions`, `_EmptyIncome`): move them onto the shared widget. Add one to Categories and Income Sources (when everything was deleted) and to the Consultant before the first message, pointing at the suggestion chips, and a variant when no Gemini key is configured.

- [x] Home, Income, Categories, Income Sources and Consultant all use `EmptyState`
- [x] Each empty state has a one-tap next step (add, or a suggested question)
- [x] Consultant without a Gemini key says the Consultant is off before the user types anything, instead of only answering with an error after they send
