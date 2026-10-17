# Skills

Copied from [mattpocock/skills](https://github.com/mattpocock/skills) at commit `49dd158` (plugin version 1.3.1), MIT licensed (see `LICENSE`). These are the 27 skills the upstream Claude Code plugin ships; the beta (`in-progress/`) and `misc/` skills were left out, and so were the Codex-only `agents/openai.yaml` files.

Start with `/ask-matt` to find the right skill for a situation. `/setup-matt-pocock-skills` has already been run for this repo: its answers are in `AGENTS.md` and `docs/agents/`.

## Changed from upstream

Everything else is a verbatim copy. Keep this list current so an upstream update can be re-applied by hand.

- `tdd/tests.md`, `tdd/mocking.md`: examples rewritten in Dart against this repo (Cubits, `IncomeLedger`, `calculateNet`, in-memory SQLite, hand-written fakes for `CloudSyncClient`).
- `codebase-design/SKILL.md`: the two "designing for testability" examples rewritten in Dart.
- `prototype/SKILL.md`: the run command is `flutter run -t lib/prototypes/<name>_prototype.dart`.
- `prototype/UI.md`: a note mapping routes, query params and the production gate onto go_router and Flutter.

## Updating

Clone upstream, copy the folders listed in its `.claude-plugin/plugin.json` over these (dropping `agents/`), then re-apply the changes above and update the commit here.
