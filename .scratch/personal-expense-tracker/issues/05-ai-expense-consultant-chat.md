# 05: AI Expense Consultant Chat Slice

**What to build:** An interactive conversational chat tab powered by Google Gemini. The `ExpenseConsultant` module injects user spending history into the prompt context, streams answers in real-time, and provides one-tap suggestion chips for rapid insight queries.

**Blocked by:** 03: Expense Logging & Instant Add Slice

**Status:** resolved

- [x] Chat screen displays an interactive conversation timeline with message bubbles
- [x] Tapping suggested chips (e.g., "Monthly Summary", "Where did I spend most?") sends pre-built prompts
- [x] AI Consultant responses stream token-by-token in real-time
- [x] The module accurately computes and embeds recent expense breakdown into the Gemini context
- [x] Clear loading and error states for offline or quota issues
