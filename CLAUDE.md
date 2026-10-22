# Claude Instructions

@AGENTS.md

## Claude Code setup

- `.claude/settings.json` pre-approves the routine commands (`flutter analyze`, `flutter test`, `flutter pub get`, read-only git) and blocks reading `.env` files.
- In cloud sessions, `.claude/hooks/session-start.sh` installs the Flutter SDK and runs `flutter pub get`, so analyze and tests work there too. When you raise the Flutter version in `pubspec.lock`, raise `FLUTTER_VERSION` in that script to match.
- Figma: call `mcp__figma__get_metadata` without `nodeId` only to list pages, then pass the smallest node that answers the question (one frame or section, not a whole page). Prefer `get_screenshot` or `get_variable_defs` on that node when you need looks or tokens rather than layer structure.
- Project skills are in `.claude/skills/`. If the `mattpocock-skills` plugin is also installed, the same skills show up twice (once with the `mattpocock-skills:` prefix); prefer the unprefixed project copies, which carry this repo's adaptations.
