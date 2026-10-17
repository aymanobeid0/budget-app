# Agent Instructions

Offline-first Flutter app for logging Expenses and Income, with an AI Expense Consultant. SQLite on the device is the source of truth; Supabase is a sync copy. Domain words (Expense, Category, Income, Income Source, Net, Expense Ledger) mean exactly what `GLOSSARY.md` says, in code, tests, UI copy and tickets.

## Commands

- `flutter pub get`, then `flutter analyze` and `flutter test` (or one file: `flutter test test/features/income/net_test.dart`). Both must be clean before a commit.
- Run the app: `flutter run --dart-define-from-file=.env` (copy `.env.example` to `.env`). Without keys the app still runs, offline and without the Consultant.
- Local Supabase: see ADR 0005 and `docs/self_hosting_supabase.md`.
- The code is not `dart format`ted. Format only the lines you touch, never whole files, so diffs stay reviewable.

## How the code is laid out

ADR 0004 is the rule: deep vertical slices under `lib/features/<feature>/`, each owning its UI, models, Cubit and one deep module (`ExpenseLedger`, `IncomeLedger`, `CategoryStore`, `AccountService`). `lib/core/` stays lean (database, sync, router, theme, config). Read `docs/adr/` before changing an area it covers.

## Conventions the code does not spell out

- **Money** is an `int` in minor units (`amountMinor`), never a `double`. Display goes through `Money.format`.
- **Ids** come from `randomId('<prefix>_')` in `lib/core/ids.dart`.
- **Only deep modules touch SQL** (`AppDatabase.raw`). Cubits and widgets call the module.
- **Every synced row** carries `updated_at`, `deleted_at` (soft delete) and `synced_at`. A mutation sets `updated_at`, clears `synced_at` and kicks the `SyncEngine`; deleting a record sets `deleted_at` so the delete can sync. Only `AccountService` wipes rows, when it clears the phone for an account switch.
- **Schema changes** need three things together: bump `_version` with an `onUpgrade` step in `lib/core/database/app_database.dart`, a case in `test/core/database/app_database_upgrade_test.dart`, and a matching SQL file in `supabase/migrations/` with row-level security per user.
- **Dependencies are injected** through constructors and wired in `lib/main.dart`. External services sit behind an interface (`CloudSyncClient`, `AuthGateway`, `ConsultantClient`) so tests can pass a fake.
- **Tests** use a real in-memory SQLite (`AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath)` after `sqfliteFfiInit`) and hand-written fakes for the external interfaces. No mocking library.
- **Commits** follow `type(scope): summary (feature NN)`, where `(feature NN)` names the ticket in `.scratch/` the commit delivers.
- **Secrets** live only in `.env` (git-ignored). Never print, commit or copy its values.

## Agent skills

Skills live in `.claude/skills/` (from [mattpocock/skills](https://github.com/mattpocock/skills), adapted to this repo; see `.claude/skills/README.md`). `/ask-matt` says which one fits a situation.

### Issue tracker

Local markdown: specs and tickets live under `.scratch/<feature-slug>/`. See [docs/agents/issue-tracker.md](docs/agents/issue-tracker.md).

### Triage labels

Canonical 5-role vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See [docs/agents/triage-labels.md](docs/agents/triage-labels.md).

### Domain docs

Single-context layout (`GLOSSARY.md` + `docs/adr/` at repo root). See [docs/agents/domain.md](docs/agents/domain.md).
