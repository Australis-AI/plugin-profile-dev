# australis-dev — Australis development capability module

Claude Code plugin that packages the Australis dev module (SDD workflow, PR/commit
flow, judgment-day review, n8n workflow analysis) so it is **inherited in every
working directory** on any machine where it is installed.

Distributed standalone via the `australis-dev` marketplace in this repo. See the
[repository README](../README.md) for install, update, and enable/disable instructions.

## Why a plugin

Claude Code does **not** inherit project skills/agents/commands by folder hierarchy:
opening Claude inside a nested repo does not pick up skills that live in a parent
`.claude/`. A **user-scope** plugin is inherited across all directories, is not
duplicated, and can be enabled/disabled to hand the harness to a non-dev.

## What's inside

- `skills/` — SDD phase skills, `branch-pr`, `chained-pr`, `work-unit-commits`,
  `issue-creation`, `judgment-day`, `go-testing`, and the `n8n-*` analysis skills.
- `agents/` — SDD phase agents (`sdd-*`) and judgment-day agents (`jd-*`).
- `commands/` — SDD slash commands (`sdd-new`, `sdd-continue`, `sdd-ff`, …).

Skills are namespaced under the plugin, e.g. `australis-dev:sdd-new`,
`australis-dev:branch-pr`.

## Not yet in the plugin

`orchestrator.md` and `dev-context.md` (the dev session's SDD orchestration and
context) live in the main Australis AI-OS repo and are read on demand there. If the
module needs to be 100% self-contained, migrate those here as skills.
