# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

The owner, plus a few friends or family who install it. It is a personal tool used every day, with no app-store launch planned. People open it on their phone right after paying for something, or on the day they are paid, and they want the entry done in seconds. Now and then they ask "where did my money go?"

## Product Purpose

A personal tracker with as little friction as possible: log Expenses (amount, Category, date) and Income (amount, Income Source, paid-on date), see Net over a period, and browse past calendar months. Deeper questions go to the Expense Consultant, a chat that reads the user's own records and answers in plain language. Success means logging takes under three seconds, the app never waits on the network, and the user understands their spending without having to read charts.

## Positioning

Logging takes under three seconds. There are no budgets, caps, charts, recurring bills or bank linking. Analysis is conversational: the Consultant runs on an AI Provider the user connects with their own key, so the app carries no shared secret and has no AI bill of its own. It works fully offline, and the device is the source of truth.

## Operating Context

- Offline-first: SQLite on the device is authoritative, and Supabase is a sync copy. Writes are local and instant.
- A guest can use the app immediately. Upgrading to an account means picking a username and password, with no OAuth (ADR 0007). Switching accounts clears the phone's synced rows.
- One global Currency is set by the user (e.g. USD $, EUR €, EGP E£), with no conversion between currencies.
- Home, the Expenses tab and the Income tab step back through past months (ADR 0008). Home is the chosen month at a glance: what was spent, with a plain ranked list by Category, and the month's Net. The Expenses and Income tabs list that month's entries, with their own ranked list by Category or Income Source.
- The Consultant streams its replies and offers quick prompt chips. AI Provider keys stay in the OS secure store and are never synced (ADR 0009).

## Capabilities and Constraints

- Domain words mean exactly what `GLOSSARY.md` says, including in UI copy: Expense, Category, Income, Income Source, Net, Expense Ledger, Expense Consultant, AI Provider, Currency. Avoid the words the glossary lists under each term (e.g. "transaction", "budget", "balance").
- The Expense model is deliberately minimal: no notes, receipts or attachments (ADR 0002). Income is a separate record, not a signed Expense (ADR 0006).
- Out of scope: budgets and limits, overspending warnings, analytics dashboards and charts, recurring automation, bank sync, multiple accounts or double-entry bookkeeping, receipt OCR, and multi-currency conversion.
- Supported AI Providers: Google Gemini, OpenAI, Anthropic Claude, Groq, OpenRouter. One is active at a time. The Consultant is not supported on Flutter web.
- Stack: Flutter with Bloc/Cubit, in deep vertical feature slices (ADR 0004).
- Adaptive means one shared look with native behavior. The brand (colors, type, surfaces, cards, category squares) is the same on both phones. Each OS keeps its own interaction conventions: navigation and back gestures, sheets, date and option pickers, dialogs and action sheets, haptics, scroll physics and system typography metrics. Components are not split into separate Material and Cupertino UIs.

## Brand Commitments

- Name: **Monex**, on the iOS display name and the Android launcher label. Package and bundle IDs stay `budget_app` so installed copies keep their data.
- The voice is plain and calm: an assistant that explains, not a budget enforcer or a notification bot.
- Identity: the Monex UI kit (Figma, file key `jddschI0n1vzzY87NjUTJB`): its four-stripe mark as the app icon, white on the brand gradient.

## Evidence on Hand

- Current visual reference: the Monex Figma UI kit (light and dark screens, Colors and Typography pages), implemented in `lib/core/theme/tokens.dart`.
- Earlier directions: `docs/design/blue/`, `docs/design/calm-ledger/`.
- Bundled fonts: Inter (OFL) for the app; Geist and Geist Mono remain in `assets/fonts/` unused.
- There are no testimonials, users beyond the owner's circle, metrics or press. Future work must not invent them.

## Product Principles

1. Speed of entry beats richness of data. Every extra field or tap has to justify itself against the three-second log.
2. Read the records, don't grade them. Show totals, entries and ranked lists, and never judge, warn or set targets.
3. Ask instead of dashboards. Questions beyond "what did this month hold" go to the Consultant.
4. The device is the truth. Nothing waits on the network, and keys and data stay with the person holding the phone.
5. Use the glossary's words everywhere, so the app reads the same in code and on screen.
