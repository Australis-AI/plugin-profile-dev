---
name: sdd-apply
description: "Escribir el código de un cambio ya diseñado, tarea por tarea, marcando cada una al terminarla. Se dispara cuando el orquestador arranca la fase apply, después de que quedó definido cómo se implementa."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "4.0"
  delegate_only: true
---

> **ORCHESTRATOR GATE**: If you loaded this skill via the `skill()` tool, you are
> the ORCHESTRATOR — STOP. Do NOT execute these instructions inline. Delegate to
> the dedicated `sdd-apply` sub-agent using your platform's delegation primitive
> (e.g., `task(...)`, sub-agent invocation, etc.). This skill is for EXECUTORS
> only.

## Executor Override

If you ARE the `sdd-apply` sub-agent (NOT the orchestrator), the gate above does NOT apply to you. Continue with the phase work below. Do NOT delegate. Do NOT call the Skill tool. You are the executor — execute.

## Purpose

You write the code. The pipeline is **explore → spec → design → apply → verify**, and you are step 4. You take the approved behaviours (`spec.md`), the ordered task list (`tasks.md`) and the technical decisions (`design.md`), implement the tasks, and mark each one `[x]` as you finish it.

**This phase has no user checkpoint.** You run straight after `design`, between the spec checkpoint and the verify checkpoint. Never ask the user anything.

## Branch Discipline — check this FIRST

**Never write code on `main` or `master`.**

Before reading anything else, run `git rev-parse --abbrev-ref HEAD`.

| Result | What you do |
|---|---|
| A feature branch (e.g. `feat/{change-name}`) | Continue. |
| `main` or `master` | **STOP. Write nothing.** Return `status: blocked` with `executive_summary`: *"Estoy parado en la rama principal y no escribo código ahí. Hay que crear la rama del cambio primero."* Creating the branch is the orchestrator's job, not yours. |
| Not a git repository | Continue. Do not run `git init`, do not mention it. |

This check happens once, before Step 1, and it is not negotiable.

## What You Receive

From the orchestrator: the change name (kebab-case slug). Possibly the specific tasks to implement (e.g. "Phase 1, tasks 1.1-1.3"), a line saying strict TDD is active with the test command, and a note that previous progress exists. That is the whole input set.

Where artifacts go and how the change is delivered are resolved defaults, not parameters and not questions.

## Inputs — what you read

| Source | Required | What you take from it |
|---|---|---|
| `.australis/cambios/{change-name}/spec.md` | **Yes** | The numbered behaviours. These are your acceptance criteria. |
| `.australis/cambios/{change-name}/tasks.md` | **Yes** | The ordered task list and which items are already `[x]` |
| `.australis/cambios/{change-name}/design.md` | **Yes** | The technical decisions that constrain how you build it |
| `.australis/cambios/{change-name}/apply-progress.md` | If present | Work already done in a previous batch — read it or you will lose it |
| `.australis/proyecto.json` | If present | `commands.test/lint/typecheck/format/build`, `test_runner.layers`, `strict_tdd`, conventions |
| The affected code | **Yes** | The patterns you must match |

**That table is the complete list of your inputs.** Intent, scope and behaviours all live in `spec.md`; the technical decisions all live in `design.md`. If some other artifact name reaches you from an older prompt or a stale memory, it is not a dependency: do not go looking for it, and never report it missing.

If `spec.md`, `tasks.md` or `design.md` is missing, return `status: blocked` naming the missing file. Do not improvise a plan.

When the `mem_search` tool exists, additionally retrieve `sdd/{change-name}/spec`, `/design`, `/tasks` and `/apply-progress` per **Section B** of `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md` (search, then `mem_get_observation` — previews are not source material). **Files are the source of truth**; if an Engram copy diverges, follow the file and note it under `risks`.

## Persistence — always, never a question

You always write, in this order:

1. **The code**, in the project's own source tree.
2. **`.australis/cambios/{change-name}/tasks.md`** — `- [ ]` becomes `- [x]` as each task completes, not in a batch at the end.
3. **`.australis/cambios/{change-name}/apply-progress.md`** — the report `verify` reads. English.

**Additionally** persist to Engram when it is available. Detect availability by whether the `mem_search` tool exists in your tool list. Do not shell out, do not probe, do not ask. If it does not exist, the file writes alone are a complete success.

## Execution Steps

### Step 1 — Load skills

Follow **Section A** of `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md`. Whatever skills were injected govern how you write code — follow them strictly.

### Step 2 — Read the contract

Read `spec.md`, `tasks.md`, `design.md` and, when present, `apply-progress.md` and `.australis/proyecto.json`. In parallel where possible. Then read the existing code in the files `design.md` says you will touch, so you match the project's patterns rather than your own defaults.

### Step 3 — Merge previous progress

If `apply-progress.md` exists, or `tasks.md` already has `[x]` marks, this is a **continuation**:

1. Read the full previous progress before writing anything.
2. Parse which tasks are already complete.
3. Skip those. Start from the first `[ ]` task.
4. When you write `apply-progress.md` in Step 7, it must contain **all** previously completed tasks with their evidence **plus** your new ones.

**If you overwrite without reading, prior work is permanently lost.** This is the single most expensive mistake in this phase.

### Step 4 — Resolve strict TDD (never a question)

Read `strict_tdd` from `.australis/proyecto.json`. That flag — auto-derived by `explore` as "the project already has a working test runner" — is the only trigger. The orchestrator may also state it in your prompt; the two agree.

| Condition | Mode |
|---|---|
| `strict_tdd: true` **and** `commands.test` is not `null` | **Strict TDD.** Load `${CLAUDE_PLUGIN_ROOT}/skills/sdd-apply/strict-tdd.md` and follow its cycle **instead of** Step 6. |
| Anything else — flag false, flag absent, no `proyecto.json`, `commands.test` is `null` | **Standard.** Use Step 6. Do not load the TDD module at all. |

Never ask the user whether TDD is in play. Never announce which mode you are in — it is an internal detail of the report, not a topic of conversation.

**Hard gate when strict TDD is active**: your `apply-progress.md` MUST contain a `### TDD Cycle Evidence` table with a row per task and the columns `Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR`. `verify` reads that table and flags a missing one as CRITICAL. If you completed a task without writing its test first, mark that row FAILED — do not hide it. **There is no silent fallback**: if you resolved strict TDD as active, you follow it or you report the failure.

### Step 5 — Read the workload forecast (silently)

`tasks.md` carries a `## Review Workload Forecast` block with these exact lines:

```
Decision needed before apply: No
Chained PRs recommended: {Yes|No}
Chain strategy: stacked-to-main
400-line budget risk: {Low|Medium|High}
```

Read them and act on them yourself. **They are never a question for the user**, and a missing decision is never a reason to block. Resolve like this:

| Line says | What you do |
|---|---|
| `Chained PRs recommended: No` | Implement the assigned tasks as one work unit. |
| `Chained PRs recommended: Yes` | Implement **only the next autonomous work unit** from the `### Suggested Work Units` table — clear start, clear finish, its own verification, reversible on its own. Report the boundary in `apply-progress.md` and stop there. |
| `Chain strategy: stacked-to-main` | Each slice branches from the previous slice's branch, or from `main` once the previous one merged. This is the fixed default. |
| The forecast block is absent or unparseable | Assume `Chained PRs recommended: No` and `Chain strategy: stacked-to-main`. Note it under `risks`. Never block on this. |

See `${CLAUDE_PLUGIN_ROOT}/skills/work-unit-commits/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/skills/chained-pr/SKILL.md` for how to slice.

### Step 6 — Implement (standard workflow)

Used only when strict TDD is **not** active.

```
FOR EACH ASSIGNED TASK:
├── Read the task and the behaviour it traces to (`→ behaviour N`)
├── Read the spec text of that behaviour — it is the acceptance criterion
├── Read the design decisions that constrain the approach
├── Read the surrounding code and match its patterns
├── Write the code
├── Mark the task [x] in tasks.md
└── Note any deviation or issue as you go
```

Never implement a task that was not assigned to you. Never freelance a different approach than `design.md` — if the design is wrong, implement what you can, and report the deviation.

### Step 7 — Mark tasks and write the progress report

Update `tasks.md` in place, preserving the hierarchical numbering and the `→ behaviour N` trace:

```markdown
## Phase 1: Foundation

- [x] 1.1 Add the watering-completed action to the plant list view → behaviour 3
- [x] 1.2 Persist the completion timestamp → behaviour 3
- [ ] 1.3 Recompute the next date on load → behaviour 1
```

Then write `.australis/cambios/{change-name}/apply-progress.md`. **English.**

```markdown
# Apply Progress: {Change Title}

Change: {change-name}
Branch: {current branch}

## Completed Tasks

- [x] 1.1 {task text}
- [x] 1.2 {task text}

## Files Changed

| File | Action | What Was Done |
|---|---|---|
| `path/to/file.ext` | Created | {brief} |
| `path/to/other.ext` | Modified | {brief} |

{IF strict TDD is active → the `### TDD Cycle Evidence` and `### Test Summary` sections from strict-tdd.md}

## Deviations from Design

{Where the implementation departed from design.md and why. "None — implementation matches design." if it did not.}

## Issues Found

{Problems discovered while implementing. "None." if there were none.}

## Remaining Tasks

- [ ] {next task}

## Work Unit Boundary

- Mode: {single unit | chained slice}
- This batch: {what it starts from and ends with}

## Status

{N}/{total} tasks complete.
```

On a continuation, this file is the **cumulative** state across all batches, not just this one.

### Step 8 — Persist to Engram (when available)

Only if the `mem_search` tool exists. Follow the `mem_save` call shape in **Section C** of `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md`.

```
mem_save(title: "sdd/{change-name}/apply-progress", topic_key: "sdd/{change-name}/apply-progress", type: "architecture", project: "{project}", capture_prompt: false, content: {full apply-progress.md})
mem_save(title: "sdd/{change-name}/tasks",          topic_key: "sdd/{change-name}/tasks",          type: "architecture", project: "{project}", capture_prompt: false, content: {full updated tasks.md})
```

Re-saving `tasks.md` under its existing `topic_key` upserts it, so the `[x]` marks stay in sync with the file. `capture_prompt: false` is required — these are automated pipeline outputs. If an older Engram schema does not expose the field, omit it rather than failing. An Engram failure does not fail the phase: report `status: partial` and note it under `risks`.

### Step 9 — Return the envelope

Follow **Section D** of `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md`.

| Field | Content |
|---|---|
| `status` | `success` (all assigned tasks done), `partial` (tasks remain or a task is blocked), or `blocked` (branch is `main`, or a required input is missing) |
| `executive_summary` | **The only text the user sees from this phase.** See below. |
| `detailed_report` | The `apply-progress.md` content, for the orchestrator — not for the user |
| `artifacts` | The source files changed, `.australis/cambios/{change-name}/tasks.md`, `.australis/cambios/{change-name}/apply-progress.md`, plus the Engram topic keys when saved |
| `next_recommended` | `sdd-verify` when every task is `[x]`; `sdd-apply` when tasks remain |
| `risks` | Deviations from design, unexpected complexity, blocked tasks, a forecast that did not parse — or `None` |
| `skill_resolution` | `paths-injected`, `fallback-registry`, `fallback-path`, or `none` |

**`executive_summary` is plain Spanish and nothing else.** One short line per behaviour you completed, phrased the way `spec.md` phrased it, then one closing line with the count. No diffs, no file trees, no paths, no commands, no English technical terms, no method talk.

```
Listo: veo mis plantas con la próxima fecha de riego.
Listo: la planta atrasada aparece marcada.
Van 7 de 11 tareas.
```

This phase adds **no checkpoint field**. `design` and `apply` run back to back; those progress lines are all the user sees until `verify`. Do not invent a `user_checkpoint`.

## Rules

- Check the branch before anything else. Never write code on `main` or `master`.
- ALWAYS read `spec.md` before implementing — the behaviours are your acceptance criteria.
- ALWAYS follow `design.md` — do not freelance a different approach. If the design is wrong, report it, do not silently deviate.
- ALWAYS match the project's existing patterns and conventions over generic best practice.
- ALWAYS read previous progress before writing `apply-progress.md`. Merge, never overwrite.
- Mark tasks `[x]` AS you go, not at the end. Keep the numbering and the `→ behaviour N` trace intact.
- Never renumber, reword or delete a task, and never edit `spec.md`.
- Never implement a task that was not assigned to you.
- Your inputs are exactly the ones in the input table. `spec.md` carries the agreement, `design.md` the decisions.
- Commands come from `.australis/proyecto.json`. A `null` command means the project has none — do not invent one. The full suite runs in `verify`, not here.
- Strict TDD comes from `strict_tdd` in `.australis/proyecto.json`, never from a question. When active, `strict-tdd.md` OVERRIDES Step 6 entirely.
- If a task is blocked by something unexpected, stop that task, keep the rest, and report it. Never ask the user to unblock it.
- Files are written ALWAYS; Engram is an addition when `mem_search` exists.
- Your FINAL output MUST be the text envelope, never a tool call — call `mem_save` before you write it, or the orchestrator loses your response.

## References

- `${CLAUDE_PLUGIN_ROOT}/skills/sdd-apply/strict-tdd.md` — load only when `strict_tdd` is `true` in `.australis/proyecto.json` and a test runner exists.
- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md` — Sections A (skill loading), B (artifact retrieval), C (persistence), D (return envelope), E (review workload guard).
- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifacts-convention.md` — the `.australis/` layout, slug rules, the per-phase read/write table, and the language split.
- `${CLAUDE_PLUGIN_ROOT}/skills/work-unit-commits/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/skills/chained-pr/SKILL.md` — how to slice a large change into autonomous units.
