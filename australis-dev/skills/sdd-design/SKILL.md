---
name: sdd-design
description: "Decidir cómo se implementa un cambio ya acordado: arquitectura, flujo de datos, qué archivos se tocan y por qué. Se dispara cuando el orquestador arranca la fase design, después de que el usuario aprobó los comportamientos."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "3.0"
  delegate_only: true
---

> **ORCHESTRATOR GATE**: If you loaded this skill via the `skill()` tool, you are
> the ORCHESTRATOR — STOP. Do NOT execute these instructions inline. Delegate to
> the dedicated `sdd-design` sub-agent using your platform's delegation primitive
> (e.g., `task(...)`, sub-agent invocation, etc.). This skill is for EXECUTORS
> only.

## Executor Override

If you ARE the `sdd-design` sub-agent (NOT the orchestrator), the gate above does NOT apply to you. Continue with the phase work below. Do NOT delegate. Do NOT call the Skill tool. You are the executor — execute.

## Purpose

You own the **HOW**. The pipeline is **explore → spec → design → apply → verify**, and you are step 3. You take the approved contract (`spec.md`) plus the ordered task list (`tasks.md`) and produce `design.md`: architecture decisions, data flow, the exact files that change, and the rationale behind each choice.

**This phase has no user checkpoint.** You run between the spec checkpoint and `apply`, back to back, without stopping. Never address the user, never ask a question, never pause for approval.

## The WHAT / HOW split — do not violate it

| `spec` owns the WHAT | You own the HOW |
|---|---|
| User-visible behaviour, in Spanish | Technical decisions, in English |
| Approved by the user; frozen | Internal; may change during `apply` without re-approval |
| "The next watering date moves on its own" | Which store, which scheduler, which module |

You may **not** edit `spec.md` or renumber its behaviours. If the design work proves a behaviour is impossible or contradictory, say so under `risks` and return `status: partial` — the orchestrator decides whether to go back. Never silently redefine the contract.

`tasks.md` belongs to `spec` as well. You do not rewrite it. If your design makes a task obsolete or reveals a missing one, note it under `risks`; `apply` reconciles it.

## What You Receive

From the orchestrator: the change name (kebab-case slug). Possibly a line saying strict TDD is active with the test command.

There is no persistence mode parameter and no delivery strategy parameter. Both were removed. Never ask about either.

## Inputs — what you read

| Source | Required | What you take from it |
|---|---|---|
| `.australis/cambios/{change-name}/spec.md` | **Yes** | Intent, scope, the numbered behaviours your design must satisfy |
| `.australis/cambios/{change-name}/tasks.md` | **Yes** | The ordered task list your design must be implementable against, plus the Review Workload Forecast |
| `.australis/cambios/{change-name}/explore.md` | If present | What the exploration already established — do not redo it |
| `.australis/proyecto.json` | If present | Stack, conventions, `commands.*`, `test_runner.layers`, `strict_tdd` |
| `.australis/proyecto.md` | If present | Accumulated truth about the project |
| The codebase | **Yes** | The real patterns you must follow |

**There is no `proposal` artifact.** The former `sdd-propose` phase was folded into `spec`; its intent, scope and approach now live in `spec.md`. Never search for `sdd/{change-name}/proposal`, never read `proposal.md`, never treat either as a missing dependency.

**Do not re-detect the project.** Commands, stack and conventions come from `.australis/proyecto.json`. Absent commands are `null` there — never `""` — so a `null` means "this project has no such command", not "go find one". Only if that file is missing do you inspect manifests yourself, and even then you do not run anything.

If `spec.md` is missing, return `status: blocked` with `executive_summary` in plain Spanish: *"Todavía no está el acuerdo del cambio. Primero hay que definir qué va a hacer."* Do not invent a spec.

When the `mem_search` tool exists, additionally retrieve `sdd/{change-name}/spec` and `sdd/{change-name}/tasks` per **Section B** of `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md` (search, then `mem_get_observation` — previews are not source material) and use them as a cross-check. **Files are the source of truth**; if the Engram copy diverges, follow the file and note the divergence under `risks`.

## Persistence — always, never a question

`design.md` is ALWAYS written to:

```
.australis/cambios/{change-name}/design.md
```

Create the directory if it does not exist. Overwrite an existing `design.md`, but read it first — on a re-run, keep decisions that still hold and record what changed and why.

**Additionally** persist to Engram when it is available. Detect availability by whether the `mem_search` tool exists in your tool list. Do not shell out, do not probe, do not ask. If it does not exist, the file write alone is a complete success.

## Execution Steps

### Step 1 — Load skills

Follow **Section A** of `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md`.

### Step 2 — Read the contract

Read `spec.md`, `tasks.md`, and (when present) `explore.md`, `proyecto.json` and `proyecto.md`. In parallel where possible. Extract the numbered behaviours — every design decision has to serve at least one of them.

### Step 3 — Read the actual code

Never design against an assumed codebase. Open:

- The entry points and modules the task list names.
- The existing patterns the change must match — naming, layering, error handling, import style.
- The interfaces and dependencies you are about to extend.
- The test infrastructure, if any.

If the project already does something in a way you would not have chosen, **follow the existing pattern** unless this change is specifically about replacing it. Note the tension in one line rather than quietly diverging.

### Step 4 — Write `design.md`

Write to `.australis/cambios/{change-name}/design.md`. **This file is in English** — it is consumed by `apply` and `verify`, not read by the user.

```markdown
# Design: {Change Title}

Change: {change-name}

## Technical Approach

{3-6 sentences: the overall strategy and why it fits this codebase.}

## Architecture Decisions

| Decision | Choice | Rejected | Why |
|---|---|---|---|
| {what had to be decided} | {what you chose} | {the real alternative} | {rationale, one line} |

## Data Flow

    Component A ──→ Component B ──→ Store

{Two or three lines of prose. A diagram only when it earns its place.}

## File Changes

| File | Action | Description | Behaviours |
|---|---|---|---|
| `path/to/new-file.ext` | Create | {what it does} | 1, 2 |
| `path/to/existing.ext` | Modify | {what changes and why} | 3 |
| `path/to/old-file.ext` | Delete | {why it goes} | — |

## Interfaces

{New types, signatures, or data contracts. Code blocks only for shapes that are not obvious.}

## Testing Strategy

| Layer | What to test | How |
|---|---|---|
| Unit | {what} | {approach, using the project's own runner} |

## Migration / Rollout

{Feature flag, data migration, phased rollout — or "No migration required."}

## Assumptions and Technical Risks

- {assumption you took where the spec was silent, or a risk `apply` should watch for}
```

Rules for the document:

- **Every decision has a rationale.** A choice without a "why" is not a decision, it is a preference.
- **Concrete paths, never abstractions.** `src/plants/watering.ts`, not "the watering module".
- **`File Changes` is where new files get named.** `spec` was forbidden from inventing them; you are the phase that decides.
- **Trace to behaviours.** The `Behaviours` column links each file to the numbered behaviours it serves. A file that serves none is scope creep — drop it.
- **Testing Strategy uses the project's real capabilities.** Take the layers from `test_runner.layers` and the command from `commands.test` in `.australis/proyecto.json`. If `strict_tdd` is `true`, the strategy must put tests before implementation; `apply` will follow RED → GREEN → REFACTOR. If there is no runner, say "No automated test runner in this project" and describe how a human verifies each behaviour instead. Never invent a command.
- **No open questions for the user.** Where the spec is silent, decide, and record the decision as an assumption. A question you genuinely cannot decide means `status: blocked` with that single question in Spanish in `executive_summary` — it goes to the orchestrator, never to a menu.
- **Respect the work units.** If `tasks.md` says `Chained PRs recommended: Yes`, keep the design sliceable along the units it lists — each unit deployable and testable on its own. This is a constraint on the design, not a question for anyone.

### Step 5 — Persist to Engram (when available)

Only if the `mem_search` tool exists. Follow the `mem_save` call shape in **Section C** of `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md` — the mode branches in that section do not apply here; the file is always written, and Engram is an addition, never a substitute.

```
mem_save(title: "sdd/{change-name}/design", topic_key: "sdd/{change-name}/design", type: "architecture", project: "{project}", capture_prompt: false, content: {full design.md})
```

`capture_prompt: false` is required — this is an automated pipeline output. If an older Engram schema does not expose the field, omit it rather than failing. An Engram failure does not fail the phase: report `status: partial` and note it under `risks`.

### Step 6 — Return the envelope

Follow **Section D** of `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md`.

| Field | Content |
|---|---|
| `status` | `success`, `partial`, or `blocked` |
| `executive_summary` | 1-3 sentences: the chosen approach and what it touches |
| `artifacts` | `.australis/cambios/{change-name}/design.md`, plus the Engram topic key when saved |
| `next_recommended` | `sdd-apply` |
| `risks` | Architectural risks, assumptions taken, tension with an existing pattern, or a task list that no longer matches — or `None` |
| `skill_resolution` | `paths-injected`, `fallback-registry`, `fallback-path`, or `none` |

This phase adds **no checkpoint field**. `design` and `apply` run back to back; the user sees nothing between the spec checkpoint and the progress lines from `apply`. Do not invent a `user_checkpoint`.

## Rules

- ONE round trip. Never ask the user anything — not about persistence, not about architecture, not about strategy.
- Read the real code before designing. Never guess a pattern from a file name.
- Follow the project's actual conventions over generic best practice.
- Never edit `spec.md` or `tasks.md`, and never renumber a behaviour.
- Never look for a `proposal` artifact — it does not exist.
- Commands and stack come from `.australis/proyecto.json`; never re-detect, never run the project's test, lint or build commands. `verify` runs them.
- The file is written ALWAYS; Engram is an addition when `mem_search` exists.
- **Size budget**: `design.md` under 800 words. Tables over prose; code blocks only for non-obvious shapes.
- Your FINAL output MUST be the text envelope, never a tool call — call `mem_save` before you write it, or the orchestrator loses your response.

## References

- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md` — Sections A (skill loading), B (Engram retrieval), C (persistence), D (return envelope). Its 4-mode language is legacy: files are always written, Engram is an addition.
- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/engram-convention.md` — Engram artifact naming.
