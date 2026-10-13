# Issue tracker: GitHub & Local Markdown

Issues and specs for this repo live as GitHub issues managed via `gh` CLI. When working offline or for quick local drafting, markdown files under `.scratch/` are supported.

## GitHub Conventions (`gh` CLI)

- **Create an issue**: `gh issue create --title "..." --body "..."` (use heredoc for multi-line bodies).
- **Read an issue**: `gh issue view <number> --json number,title,body,labels,comments`.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'`.
- **Make an issue a sub-issue of a parent**: `gh issue create --parent <parent> ...`, or `gh issue edit <parent> --add-sub-issue <child>`.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

## Pull requests as a triage surface

**PRs as a request surface: no.** *(Set to `yes` if this repo treats external PRs as feature requests; `/triage` reads this flag).*

## Local Markdown Convention (`.scratch/`)

- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`.
- Triage state is recorded as a `Status:` line near the top of each issue file (see [triage-labels.md](file:///d:/budget-app/docs/agents/triage-labels.md) for role strings).
- Comments append to the bottom of the file under a `## Comments` heading.

## When a skill says "publish to the issue tracker"

Create a GitHub issue (or a local markdown spec/ticket in `.scratch/<feature-slug>/` if offline).

## When a skill says "fetch the relevant ticket"

Read it via `gh issue view` or the file at the referenced `.scratch/` path.

## Wayfinding operations

Used by `/wayfinder`. The **map** is tracked via GitHub (issue labeled `wayfinder:map`) or locally under `.scratch/<effort>/map.md`.
