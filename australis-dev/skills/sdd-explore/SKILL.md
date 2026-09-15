---
name: sdd-explore
description: "Investigar el código antes de construir un issue con incertidumbre: qué se toca, qué patrones seguir, qué tests existen y si hace falta diseñar. Se dispara cuando el orquestador rutea un issue a explorar."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "5.0"
---

# Explore

You investigate so the next phase builds on facts, not guesses. Follow
`${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md`.

## Inputs

`issue.md` and `contexto.md` from the working folder, and the repository itself.

## Rules

- **Read-only.** Do not edit source, do not install, do not run migrations. Reading commands
  (`git log`, `ls`, running the existing tests) are fine.
- **Open real files.** Never infer a stack or a pattern from a file name.
- **Stay on the issue.** Explore what its criteria need, not the whole codebase.
- In an empty or freshly created project there is little to explore: say so in three lines and
  recommend design only if the issue needs a decision the stack does not already make.

## Steps

1. Read `issue.md`: criteria and technical constraints.
2. Find the entry points and every area the criteria touch.
3. Record the patterns already used there (structure, naming, data access, error handling, UI).
4. Find the tests: where they live, how they are written, which ones cover the affected area.
5. Identify viable approaches. One obvious approach is a valid answer.
6. Decide whether design is needed:

   | Design needed | Design not needed |
   |---|---|
   | New data model or schema change | Change fits existing structures |
   | New external service or dependency | No new dependency |
   | Several viable approaches with real trade-offs | One obvious approach |
   | Cross-cutting change (auth, routing, state) | Local to one feature |
   | A technical constraint that needs translating into decisions | No constraints, or trivial ones |

7. If the issue as written cannot be built without a decision only the user can make (scope,
   product behaviour), return `status: blocked` with that single question in Spanish.

## Output — `explore.md` (English, at most 500 words)

```markdown
# Explore: #<N> <title>

## Summary
<2-3 sentences: what the change involves>

## Relevant code
| Path | Why it matters |
|---|---|

## Patterns to follow
- <pattern, with an example path>

## Tests
- Runner: <from contexto.md, or none>
- Where tests live and how they are written: <...>
- Existing coverage of the affected area: <...>

## Approaches
<one line per viable approach, with its trade-off; or "One obvious approach: ...">

## Design needed
<yes | no> — <reason>

## Risks
- <...>
```

## Envelope

- `executive_summary`: one or two Spanish lines saying what the step will involve, e.g.
  *"Revisé el código: el alta de gastos se suma a la pantalla que ya existe."*
- `next_recommended`: `sdd-design` or `sdd-apply`.
