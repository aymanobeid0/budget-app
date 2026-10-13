# 05: AI Expense Consultant Chat Slice

**What to build:** An interactive conversational chat tab powered by Google Gemini. The `ExpenseConsultant` module injects user spending history into the prompt context, streams answers in real-time, and provides one-tap suggestion chips for rapid insight queries.

**Blocked by:** 03: Expense Logging & Instant Add Slice

**Status:** ready-for-agent

- [ ] Chat screen displays an interactive conversation timeline with message bubbles
- [ ] Tapping suggested chips (e.g., "Monthly Summary", "Where did I spend most?") sends pre-built prompts
- [ ] AI Consultant responses stream token-by-token in real-time
- [ ] The module accurately computes and embeds recent expense breakdown into the Gemini context
- [ ] Clear loading and error states for offline or quota issues
