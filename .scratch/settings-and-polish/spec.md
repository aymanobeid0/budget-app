# Settings & Polish

**Status:** ready-for-agent

Finishes ticket 06 of the original spec (`.scratch/personal-expense-tracker/issues/06-global-currency-and-settings.md`, user stories 8, 9 and 1 in `.scratch/personal-expense-tracker/spec.md`), plus the "sync on reconnect" promise from ticket 04 that never got built.

Decisions made for this spec (2026-10-17):

- **Currency** stays a display label only (GLOSSARY.md: no conversion, no multi-currency). The choices are MRU (the default, today's hard-coded label), USD, EUR, EGP and SAR, shown as the code next to amounts as today ("3,980 MRU"). The choice is stored on the device like the Net period preference.
- **Reconnect** is detected without a new plugin: a failed or offline sync retries on a backoff timer, and the app syncs when it comes back to the foreground.
- **Google sign-in is out of scope.** Accounts stay username + password because each account maps to its own per-user data (see `docs/accounts.md`).

Tickets are in `issues/`. The four are independent of each other.
