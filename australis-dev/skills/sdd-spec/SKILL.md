---
name: sdd-spec
description: "Define el contrato del cambio antes de escribir código: alcance, comportamientos numerados que el usuario aprueba y las tareas ordenadas. Trigger: fase spec del orquestador, qué va a hacer esto, definí el alcance."
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
> the dedicated `sdd-spec` sub-agent using your platform's delegation primitive
> (e.g., `task(...)`, sub-agent invocation, etc.). This skill is for EXECUTORS
> only.

## Executor Override

If you ARE the `sdd-spec` sub-agent (NOT the orchestrator), the gate above does NOT apply to you. Continue with the phase work below. Do NOT delegate. Do NOT call the Skill tool. You are the executor — execute.

## Purpose

You are a sub-agent that produces, in ONE round trip, **the contract the user approves before any code is written**:

1. **Intent and scope** — what problem this solves, what is in and what is out.
2. **Numbered, testable, user-visible behaviours** — the heart of this phase.
3. **An ordered implementation task list** — plus a Review Workload Forecast.

The pipeline is **explore → spec → design → apply → verify**. You are the single planning phase: intent, scope, behaviours and tasks all land in one round trip, and the result is the contract the user approves before any code is written.

## The WHAT / HOW split — do not violate it

| This phase (`spec`) owns the WHAT | The next phase (`design`) owns the HOW |
|---|---|
| User-visible behaviour | Technical decisions |
| Approved by the user; must stay stable | Internal; may change without re-approval |
| "The next watering date moves on its own" | Which store, which scheduler, which module |

Hard rule: **no architecture and no technology in the spec artifact.** No library names, no framework names, no database names, no module or class names, no file trees. If a behaviour cannot be stated without naming a technology, state the behaviour and leave the technology to `design`.

The task list is the one place where concrete file paths are allowed, and only for files that **already exist**. Do not invent new modules, layers, or file structures — `design` decides those, and `apply` follows `design`.

## What You Receive

From the orchestrator:
- Change name (kebab-case slug, e.g. `add-dark-mode`). If none was given, derive one from the user's request.
- The exploration result, or the user's direct description of the change.

You receive no persistence mode and no delivery strategy: both are fixed defaults you apply yourself. Never ask the user about either.

## Persistence — always, never a question

Artifacts are ALWAYS written to files:

```
.australis/cambios/{change-name}/
├── spec.md      ← intent, scope, numbered behaviours, estimate
└── tasks.md     ← Review Workload Forecast + ordered task list
```

Create the directory if it does not exist. Overwrite these two files if they already exist — but read them first so you do not lose an already approved behaviour list (see the stability rule in Step 3).

**Additionally** persist to Engram when it is available. Detect availability by whether the `mem_search` tool exists in your tool list. Do not shell out, do not probe, do not ask. If it does not exist, the file write alone is a complete success.

## What to Do

### Step 1 — Load Skills

Follow **Section A** from `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md`.

### Step 2 — Gather Context

Read, in parallel where possible:

- `.australis/cambios/{change-name}/explore.md` if it exists.
- If `mem_search` exists: `sdd/{change-name}/explore` via **Section B** of `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md` (search, then `mem_get_observation` — previews are NOT source material).
- `.australis/cambios/{change-name}/spec.md` and `tasks.md` if a previous run left them.
- Enough of the codebase to size the change honestly — entry points and the files it most likely touches. Read to estimate, not to design.

If a detail is genuinely ambiguous, **do not stop to ask**. Take the most conservative reading, record it as an assumption in the spec, and list it under `risks` in the envelope. Return `status: blocked` only when the change cannot be scoped at all — and then put the single question, in plain Spanish, in `executive_summary`.

### Step 3 — Write the Numbered Behaviours

This is the most important output of the whole phase. The orchestrator shows this list to the user as the checkpoint **"Esto va a hacer"**, and the `verify` phase reuses it verbatim at the end with ✅/❌ per item.

Rules for each behaviour:

- **Plain Spanish**, understandable by a non-technical person. No jargon, no English technical terms.
- **User-visible.** It describes something the person does, sees, or receives — not something the system does internally.
- **Testable.** Someone using the product must be able to mark it ✅ or ❌ without reading code.
- **One sentence.** Present tense, concrete.
- **Numbered from 1**, in the order the user would encounter them.
- **No technology.** If the sentence needs a library, a table, or an endpoint to make sense, it is a design decision — rewrite it as behaviour.

Good:

```
1. Abro la app y veo mis plantas con la próxima fecha de riego.
2. Si una planta está atrasada, aparece marcada en rojo.
3. Toco "Regada" y la próxima fecha se corre sola.
```

Bad — reject and rewrite these shapes:

```
1. Se agrega un endpoint POST /waterings.        ← technology, not behaviour
2. Mejorar la experiencia de riego.              ← not testable
3. El sistema persiste el evento en la tabla.    ← internal, not user-visible
```

Aim for **3 to 8 behaviours**. More than 10 means the change should be split — say so in the forecast.

**Stability rule**: once a numbered list has been approved, wording and numbers are frozen. On a re-run, keep approved items verbatim with their original numbers, append new ones at the end, and mark a dropped one `(retirado)` instead of renumbering. `verify` matches by number and by wording.

### Step 4 — Write `spec.md`

Write to `.australis/cambios/{change-name}/spec.md`. **The whole file is in Spanish** — it is the contract a person reads and approves.

```markdown
# {Título del cambio}

Cambio: {change-name}

## Intención

{2-4 oraciones: qué problema resuelve y por qué ahora. Sin tecnología.}

## Alcance

**Entra**
- {entregable concreto}
- {entregable concreto}

**No entra**
- {lo que explícitamente no se hace ahora}

## Comportamientos

1. {comportamiento visible, testeable, una oración}
2. {...}
3. {...}

## Estimación

Alrededor de {N} archivos · {tiempo estimado, por ejemplo "media jornada"}

## Supuestos

- {supuesto que tomaste ante una ambigüedad — omitir la sección si no hay ninguno}
```

The heading `## Comportamientos` is a fixed contract: `verify` looks for exactly that heading. Do not rename or translate it.

### Step 5 — Write `tasks.md`

Write to `.australis/cambios/{change-name}/tasks.md`. **This file is in English** — it is consumed by `design` and `apply`, not read by the user.

```markdown
# Tasks: {Change Title}

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | {rough number or range} |
| 400-line budget risk | Low / Medium / High |
| Chained PRs recommended | Yes / No |
| Suggested split | {single PR, or PR 1 → PR 2 → PR 3} |

Decision needed before apply: No
Chained PRs recommended: {Yes|No}
Chain strategy: stacked-to-main
400-line budget risk: {Low|Medium|High}

### Suggested Work Units
<!-- Only when Chained PRs recommended is Yes. Otherwise write "Single PR." -->

| Unit | Goal | Likely PR |
|------|------|-----------|
| 1 | {standalone deliverable, with its own tests} | PR 1 |
| 2 | {standalone deliverable} | PR 2 |

## Phase 1: {Foundation}

- [ ] 1.1 {concrete action} → behaviour 1
- [ ] 1.2 {concrete action} → behaviour 1, 2

## Phase 2: {Core}

- [ ] 2.1 {concrete action} → behaviour 3

## Phase 3: {Verification}

- [ ] 3.1 {test that proves behaviour 1} → behaviour 1
```

Task rules:

| Criteria | Good ✅ | Bad ❌ |
|----------|---------|--------|
| Specific | "Add the watering-completed action to the existing plant list view" | "Add watering" |
| Verifiable | "Test: marking watered moves the next date forward one interval" | "Make sure it works" |
| Small | One file or one logical unit | "Implement the feature" |
| Traced | Ends with `→ behaviour N` | No link to the contract |

- Hierarchical numbering (`1.1`, `2.3`) and `- [ ]` checkboxes are a contract with `apply`, which marks them `[x]`. Keep the format exactly.
- Order by dependency: nothing in Phase 1 may depend on Phase 2.
- **Every numbered behaviour MUST be covered by at least one task.** Check this before returning.
- Name only files that already exist. New file names are `design`'s call.
- If the project uses TDD, sequence RED → GREEN → REFACTOR tasks.

### Step 6 — Resolve the Review Workload Forecast silently

The forecast is a signal for the orchestrator, **never a question for the user**. Delivery and chain strategy are the fixed constants above; emit them and move on.

Resolve it like this, with no interruption:

1. Estimate changed lines (`additions + deletions`) from file count, integration points, tests, docs and migrations. It is a planning guard, not an exact diff.
2. Set `400-line budget risk` from that estimate: under ~250 → `Low`; ~250-400 → `Medium`; over ~400 → `High`.
3. Set `Chained PRs recommended` to `Yes` only when risk is `High`; otherwise `No`. When `Yes`, split the tasks into autonomous work units, each with a clear start, finish, tests and rollback.
4. **`Decision needed before apply` is always `No`.** This phase never blocks on a delivery decision.
5. **`Chain strategy` is always the fixed default `stacked-to-main`.** Never ask; never leave it `pending`.

Keep those four plain-text lines verbatim — downstream guards match them literally.

### Step 7 — Persist to Engram (when available)

Only if the `mem_search` tool exists. Follow the `mem_save` call shape in **Section C** of `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md` — the mode branches in that section do not apply here; files are always written, and Engram is an addition, never a substitute.

Save **two** artifacts, keeping the `sdd/{change-name}/{artifact}` convention:

```
mem_save(title: "sdd/{change-name}/spec",  topic_key: "sdd/{change-name}/spec",  type: "architecture", project: "{project}", capture_prompt: false, content: {full spec.md})
mem_save(title: "sdd/{change-name}/tasks", topic_key: "sdd/{change-name}/tasks", type: "architecture", project: "{project}", capture_prompt: false, content: {full tasks.md})
```

`capture_prompt: false` is required — these are automated pipeline outputs. If an older Engram schema does not expose the field, omit it rather than failing. An Engram failure does not fail the phase: report `status: partial` and note it under `risks`.

### Step 8 — Return the Envelope

Follow **Section D** from `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md`, **plus the one field this phase adds**.

| Field | Content |
|-------|---------|
| `status` | `success`, `partial`, or `blocked` |
| `executive_summary` | 1-3 sentences: what the change does and how big it is |
| `user_checkpoint` | **The numbered behaviour list, verbatim, plus one estimate line.** See below. |
| `artifacts` | `.australis/cambios/{change-name}/spec.md`, `.australis/cambios/{change-name}/tasks.md`, and the two Engram keys when saved |
| `next_recommended` | `sdd-design` |
| `risks` | Assumptions taken, ambiguities, split recommendation — or `None` |
| `skill_resolution` | `paths-injected`, `fallback-registry`, `fallback-path`, or `none` |

**`user_checkpoint` is the field the orchestrator renders as the checkpoint "Esto va a hacer", and the field `verify` reads at the end of the cycle.** It carries the `## Comportamientos` list copied character for character from `spec.md`, followed by exactly one estimate line. Nothing else: no headings, no spec prose, no file tree, no jargon.

```
1. Abro la app y veo mis plantas con la próxima fecha de riego.
2. Si una planta está atrasada, aparece marcada en rojo.
3. Toco "Regada" y la próxima fecha se corre sola.

Estimado: alrededor de 4 archivos · media jornada.
```

`user_checkpoint` is mandatory even when Engram was unavailable — it is the phase's real output. If `verify` does not receive the envelope, it falls back to the `## Comportamientos` section of `.australis/cambios/{change-name}/spec.md`.

## Rules

- ONE round trip. Do not ask the user anything mid-phase — not about persistence, not about delivery strategy, not about scope.
- No architecture, no technology names, no file trees in `spec.md`.
- Every behaviour is user-visible, testable, and in plain Spanish; every behaviour has at least one task.
- Approved behaviour wording and numbering are frozen across re-runs.
- `spec.md` is Spanish; `tasks.md` is English; this SKILL and your reasoning are English.
- Files are written ALWAYS; Engram is an addition when `mem_search` exists.
- **Size budgets**: `spec.md` under 500 words; `tasks.md` under 450 words. Tables and checklists, not prose.
- Your FINAL output MUST be the text envelope, never a tool call — call `mem_save` before you write it, or the parent loses your response.
