Status: ready-for-agent

# Specification: Personal Expense Tracker with AI Consultant

## Problem Statement

Individuals often struggle to track everyday personal expenses because traditional finance apps are overloaded with complex double-entry accounting, mandatory bank linking, rigid budgeting envelopes, and high-friction entry forms. Users need a quick, frictionless way to log what they spent in seconds, while still being able to understand where their money went and ask natural questions about their spending habits without navigating dense spreadsheet charts.

## Solution

A streamlined, cross-platform personal expense tracking application built with Flutter. Logging an expense is reduced to three essential fields: Amount, Category, and Date. Expenses are stored offline-first in local SQLite for instantaneous loading and writes, and synchronized seamlessly with Supabase. Rather than forcing complex dashboard analytics, users have an on-demand, interactive AI Expense Consultant powered by Google Gemini to ask conversational questions about their spending patterns, highlight anomalies, and receive personalized financial tips.

## User Stories

1. As a mobile user, I want to open the app and instantly see an Add Expense button, so that I can record a purchase in less than three seconds.
2. As a user, I want to enter a numeric amount for an expense, so that my recorded financial outflow is accurate.
3. As a user, I want to select a category from intuitive visual presets (e.g. Food, Transport, Utilities), so that my expenses are clearly classified.
4. As a user, I want the expense date to default to today, with an option to pick a past date, so that logging current purchases is instant while retrospective logging is easy.
5. As a user, I want to see a reverse-chronological list of all my logged expenses grouped by day, so that I have immediate visibility over recent spending.
6. As a user, I want to delete or edit an erroneously logged expense, so that my ledger remains accurate.
7. As a user, I want to create, rename, and delete custom categories, so that the classification reflects my unique lifestyle.
8. As a user, I want to choose my preferred global currency (e.g. USD $, EUR €, EGP E£) in settings, so that amounts display in my local formatting.
9. As a user, I want the app to function with zero lag and work 100% offline, so that I can log expenses without depending on internet connectivity.
10. As a user, I want to begin using the app immediately as an anonymous guest with no signup wall, so that there is zero friction on first launch.
11. As a user, I want an option to sign in with an email or Google account, so that my expenses sync across my phone and laptop via Supabase.
12. As a user, I want a dedicated AI Consultant chat tab, so that I can ask conversational questions about my spending habits.
13. As a user, I want the AI Consultant to stream its answer in real-time, so that I do not have to wait for the complete response to load.
14. As a user, I want to ask questions like "How much did I spend on Food this month?", so that I get fast answers without calculating manual totals.
15. As a user, I want to ask questions like "Where did most of my money go last week?", so that I gain instant clarity on my largest spending leaks.
16. As a user, I want the AI Consultant to suggest follow-up questions or actionable tips, so that I can make better informed decisions about saving.
17. As a user, I want quick pre-filled prompt chips in the chat (e.g. "Monthly Summary", "Top Categories"), so that I can query insights with a single tap.
18. As a user, I want my financial records and questions kept secure and private, so that only authenticated sessions can read my Supabase data.

## Implementation Decisions

- **Architectural Pattern**: Deep vertical feature slices (`features/expenses/`, `features/categories/`, `features/consultant/`) with a lean `core/` directory for theme, network, database, and routing.
- **State Management**: Bloc/Cubit at the feature UI seam, providing unidirectional event/state streams.
- **Offline-First Persistence & Local Docker Backend**: `ExpenseLedger` deep module encapsulates both a local SQLite cache and a local Supabase instance running via Docker container (`docker-compose.yml`). Writes persist locally first, then asynchronously sync to the local/remote Supabase PostgreSQL instance.
- **Cross-Feature Seam**: `ExpenseConsultant` receives the `ExpenseLedger` interface via dependency injection to retrieve expense history context when assembling Gemini system prompts.
- **AI Integration**: Google Gemini (via Gemini API) streaming completions, formatted with localized user currency context and aggregated spending summaries.
- **Minimalist Data Model**: The `Expense` model contains strictly `id`, `amount`, `categoryId`, `date`, and `createdAt`. No notes, receipt attachments, or multi-account attributes.
- **Authentication**: Anonymous-first authentication via Supabase Auth, with optional upgrade to persistent credentials.

## Testing Decisions

- **Test Surface = Module Interface**: Tests will exercise behavior only through the external interfaces (`ExpenseLedger`, `CategoryStore`, `ExpenseConsultant`), never inspecting internal SQL strings or intermediate HTTP payloads.
- **Local Ledger Testing**: Validate that calling `log(expense)` and `delete(id)` immediately updates reactive stream subscribers and reflects in local storage.
- **Deterministic AI Testing**: Test `ExpenseConsultant` using an in-memory fake LLM adapter to verify that prompt context builder accurately aggregates date ranges and categories without making live billable API calls.
- **Widget / Cubit Tests**: Test high-level UI flows (submitting the expense form, picking a category, displaying chat responses) with in-memory test doubles.

## Out of Scope

- Multi-account double-entry bookkeeping (Checking, Savings, Credit Cards).
- Debt, loan, or investment portfolio tracking.
- Bank account auto-syncing (Plaid / Open Banking).
- Receipt OCR photo scanning and geo-location tracking.
- Fixed monthly budget limits, progress warning bars, and overspending notifications.
- Recurring subscription engines and automated bill generation.

## Further Notes

- References:
  - [GLOSSARY.md](file:///d:/budget-app/GLOSSARY.md)
  - [ADR 0001: Simplified Expense Tracker with Supabase Backend](file:///d:/budget-app/docs/adr/0001-simplified-expense-tracker-with-supabase.md)
  - [ADR 0002: Minimalist Expense Logging and Conversational AI Consultant](file:///d:/budget-app/docs/adr/0002-minimalist-expense-logging-and-chat-consultant.md)
  - [ADR 0003: Google Gemini AI Consultant and Anonymous-First Supabase Auth](file:///d:/budget-app/docs/adr/0003-google-gemini-and-anonymous-auth.md)
  - [ADR 0004: Deep Vertical Feature Slices with Bloc](file:///d:/budget-app/docs/adr/0004-deep-vertical-slices-with-bloc.md)
