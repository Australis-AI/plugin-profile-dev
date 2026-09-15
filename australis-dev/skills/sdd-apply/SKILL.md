---
name: sdd-apply
description: "Escribir el código de un issue, tarea por tarea, con commits por unidad de trabajo en la rama del issue. Se dispara cuando el orquestador arranca la fase apply, o una corrección después de verificar o revisar."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "5.0"
---

# Apply

You write the code for issue N on its branch. Follow
`${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md` — section D (branch rule) first.

## Modes

Your prompt says which one:

| Mode | Input that drives the work |
|---|---|
| **normal** | `design.md` Tasks when design ran; otherwise derive tasks from the issue criteria |
| **continuation** | `apply-progress.md` exists: read it fully, skip completed tasks, merge — never overwrite |
| **correction** | `verify.md` failures or the confirmed review findings listed in your prompt become the tasks |

## Inputs

`issue.md` (the criteria), `contexto.md` (commands), `baseline.md`, `design.md` and `explore.md`
when they exist, `apply-progress.md` when continuing, and the code you will touch. Read the
surrounding code before writing, so you match the project's patterns.

## Steps

1. **Branch check** (common contract, section D).
2. **Tasks.** With design: its Tasks section. Without design: write 2–6 tasks, each tracing to a
   criterion, into `apply-progress.md` before coding.
3. **Implement.**
   - With `STRICT TDD MODE IS ACTIVE`: load `${CLAUDE_PLUGIN_ROOT}/skills/sdd-apply/strict-tdd.md`
     and follow its cycle for every task.
   - Otherwise, for each task: read the criterion, write the code, and record the runtime check
     that shows it works.
   - Never freelance away from `design.md`. If the design is wrong, implement what you can and
     report the deviation.
   - Never touch what no task asks for.
4. **Commit per work unit.** A work unit is one criterion or one coherent piece that leaves the
   code working.
   - `git add <files>` and `git commit -m "<type>(<scope>): <subject>"` as **separate** commands.
   - Conventional commits in English, imperative, lowercase subject.
   - Never commit `.env*` (except `.env.example`), keys or tokens; the guard hook blocks them.
   - Never add AI attribution trailers. Never push: the orchestrator pushes.
5. **Run the tests** you touched (the full suite runs in verify). Never leave a new failure
   behind without reporting it.
6. **Write `apply-progress.md`** (below), cumulative across batches.

## Output — `apply-progress.md` (English)

```markdown
# Apply progress: #<N> <title>

Branch: <branch>
Mode: <normal | continuation | correction>

## Tasks
- [x] 1. <task> → criterion <n>
- [ ] 2. <task> → criterion <n>

## Files changed
| File | Action | What was done |
|---|---|---|

## Commits
- <sha> <message>

<with strict TDD: the TDD Cycle Evidence and Test Summary sections from strict-tdd.md>

## Runtime checks (no runner)
| Criterion | What was run | Result |
|---|---|---|

## Deviations from design
<or "None">

## Issues found
<or "None">

## Status
<done>/<total> tasks
```

## Envelope

- `status`: `success` when every task is done, `partial` when tasks remain, `blocked` on the
  default branch or a missing input.
- `executive_summary`: Spanish, one line per criterion addressed, then the count. Say *"Escrito"*,
  never *"Listo"* or ✅: nothing is done until verify proves it.

```
Escrito: cargar un gasto con monto y descripción.
Escrito: el total del mes se actualiza al cargar.
Van 2 de 3.
```

- `next_recommended`: `sdd-verify` when all tasks are done, `sdd-apply` otherwise.
