---
name: sdd-design
description: "Decidir cómo se construye un issue: decisiones técnicas con la alternativa descartada, archivos que se tocan, estrategia de pruebas y tareas. Se dispara cuando explore indica que hace falta diseñar."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "5.0"
---

# Design

You decide HOW the issue gets built. The WHAT is fixed by the issue. Follow
`${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md`.

## Inputs

`issue.md`, `explore.md`, `contexto.md`, and the skills injected in your prompt (dev-context
always; the stack reference when the project uses the Australis stack).

## Rules

- **Every decision has a reason and a rejected alternative.** A decision without a reason gets
  reversed by the next person.
- **Every file change serves a criterion.** A file that serves none is scope creep: drop it.
- **Technical constraints in the issue are binding.** Record each as a decision with *"user
  constraint"* as its reason.
- **Follow the project.** Existing patterns beat generic best practice. With the Australis stack,
  its reference defines structure.
- **No questions for the user.** Where the issue is silent, decide and record it as an
  assumption. A decision that is genuinely the user's (product behaviour, scope) means
  `status: blocked` with that single question in Spanish.
- Under 800 words. This is a working document, not documentation. Decisions that will outlive the
  issue (a new service, a data model, an architectural rule) are flagged for an ADR.

## Output — `design.md` (English)

```markdown
# Design: #<N> <title>

## Context
<2-4 sentences: the problem and the constraints that shape the solution>

## Decisions
| Decision | Chosen | Rejected alternative | Why |
|---|---|---|---|

## Data flow
<short description or a small ASCII diagram>

## File changes
| File | Action | Criterion it serves |
|---|---|---|

## Interfaces
<types, function signatures, API shapes, table definitions that other code depends on>

## Testing strategy
| Criterion | Test layer | What the test asserts |
|---|---|---|
<without a runner: the runtime check verify will run for each criterion>

## Tasks
- [ ] 1. <task> → criterion <n>
- [ ] 2. <task> → criterion <n>

## Migration and rollout
<schema changes (always additive), data backfill, feature flags — or "None">

## ADR candidates
<decisions worth a permanent ADR — or "None">

## Risks
- <...>
```

## Envelope

- `executive_summary`: one Spanish line, e.g. *"Decidí cómo hacerlo: se guarda en la base y la
  pantalla se actualiza sola."*
- `next_recommended`: `sdd-apply`.
