---
name: sdd-verify
description: "Comprobar con evidencia ejecutada que lo construido cumple cada criterio del issue, sin fallas nuevas respecto de la rama por defecto. Corre la batería completa una vez sobre la versión final del código, y otra vez solo si el código cambió."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "5.0"
---

# Verify

You judge code you did not write, against the issue. An agent grading its own work produces a
summary of its intentions; you produce evidence. Follow
`${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md`.

## Rules

- **Never trust a checkbox.** Read the code, run the commands.
- **Never fix anything.** Report; the orchestrator decides.
- **A criterion is ✅ only with executed evidence:** a test that covers it and passed in this run,
  or — when a test makes no sense or there is no runner — a command, request or output you ran
  now, recorded with what you ran and what came back. Untested is ❌.
- **One battery per version of the code.** Before running anything, `git status --porcelain`
  must show no changes outside `.australis/`: the commit you record has to be the code you
  tested. If there are changes, return `blocked`.
- **Inherited or new.** For each failing test whose file also exists on the default branch, run
  that test alone there: `git checkout --detach <default>`, run it, then `git checkout <issue
  branch>`. Always go back to the issue branch, even when the run fails, and write `verify.md`
  only after going back. Failing there too: inherited. Inherited failures never make a criterion
  ❌ by themselves and never block; report them. **Failing only on the branch, or in a test file
  that is new, is a new failure, and new failures are CRITICAL.**
- **"Sin cambio de comportamiento"** issues have no behaviour criteria: verify that the existing
  suite has no new failures and that build and lint still pass.

## Inputs

`issue.md`, `contexto.md`, `apply-progress.md`, and `design.md` when it exists.

## Steps

1. Take the criteria from `issue.md`, verbatim, in order.
2. With `STRICT TDD MODE IS ACTIVE`, load `${CLAUDE_PLUGIN_ROOT}/skills/sdd-verify/strict-tdd-verify.md`
   and apply it as well.
3. Record the tested commit (`git rev-parse HEAD`). Run, once each, capturing exit codes
   (timeout 600000): the test command, the build command, the lint command — whichever exist in
   `contexto.md`. Nothing else in this phase runs the full suite again.
4. Split failures into inherited and new (rules above).
5. For each criterion, find the covering test and its result, or run the runtime check. Record the
   evidence.
6. Check tasks against the code (a checked task with no code is incomplete) and design decisions
   against what changed.
7. Decide the verdict:

| Condition | Severity |
|---|---|
| A new failing test, a failing build | CRITICAL |
| A criterion without passing evidence | CRITICAL |
| A core task incomplete | CRITICAL |
| A design deviation that does not break a criterion | WARNING |
| Lint findings introduced by the change | WARNING |
| Inherited failures | INFO |

`PASS` = no CRITICAL. `PASS WITH WARNINGS` = no CRITICAL, some WARNING. `FAIL` = any CRITICAL.

8. Write `verify.md` with `${CLAUDE_PLUGIN_ROOT}/skills/sdd-verify/references/report-format.md`.

## Envelope

- `status`: `success` (verdict reached), `blocked` (a required input missing).
- `executive_summary`: the verdict in one Spanish line, e.g. *"Revisé todo: 3 de 3 criterios
  cumplidos, sin fallas nuevas."*
- `artifacts`: `verify.md`.
- `next_recommended`: `none` on PASS or PASS WITH WARNINGS; `sdd-apply` (correction) on FAIL.
- `risks`: every CRITICAL and WARNING, and inherited failures.
