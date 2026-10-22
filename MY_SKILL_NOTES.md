# Skill frontmatter: making heavy skills cheaper

"Heavy skills can be scoped down or run with a cheaper model via skill frontmatter" means a skill's header (the YAML block between the `---` lines at the top of its `SKILL.md`) can control how expensive the skill is to run, not only what it says.

## 1. Run it on a cheaper model

A `model:` field makes the skill run on that model instead of the session's model (Opus). That suits mechanical work that needs little reasoning:

```yaml
---
name: pr
description: "Use when writing a PR body."
model: haiku
---
```

## 2. Scope it down

- **`allowed-tools:`** limits which tools the skill may use. For example, a review skill could be limited to `Read, Grep, Glob, Bash(git diff:*)`. That stops it wandering off and editing files, and keeps it shorter.
- **`context: fork`**, optionally with `agent:`, runs the skill in its own sub-agent. Its file reads and searches stay out of the main conversation, and only its final report comes back. This is the biggest saving for skills that read a lot.
- **`disable-model-invocation: true`** means only you can start the skill, by typing `/name`. Claude can't pick it up on its own. It doesn't make a run cheaper, but it prevents runs you didn't ask for. These skills already use it: `grill-with-docs`, `implement`, `implement-spec`, `handoff`, `retro`, `ask-matt`, `grill-me`, `improve-codebase-architecture`.

## Suggestions for this repo

| Skill | Suggestion | Why |
|---|---|---|
| `research` | `context: fork` + a cheaper model | Lots of reading, and only the notes file matters |
| `pr`, `handoff`, `retro` | `model: sonnet` or `haiku` | Writing a summary from material that already exists |
| `code-review` | `allowed-tools` limited to read-only plus git | It only reads, and it already sends the two reviews to sub-agents |
| `grilling`, `tdd`, `implement` | Leave on the main model, no fork | They need the conversation and your answers along the way, and a forked skill can't ask you questions |

## Caveats

- The fields above are right in general, but the exact names and accepted values (for example whether `model:` takes `haiku` or a full model ID) depend on the Claude Code version. Check the Claude Code skills docs before relying on them.
- `.claude/skills/README.md` says these skills are adapted from mattpocock/skills. Record any header changes there so the adaptations stay in one place.
