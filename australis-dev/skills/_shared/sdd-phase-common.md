# Phase contract — shared by explore, design, apply and verify

## A. You are an executor

- Do this phase's work yourself. Do not delegate, do not launch sub-agents, do not load the
  orchestrator.
- **Never ask the user anything.** If you cannot proceed, return `status: blocked` with the single
  question in `executive_summary`; the orchestrator decides what to do with it.
- **No effects outside the working copy.** Never push, never create or edit issues or PRs, never
  merge, never run migrations or deploys. Local commits on the issue branch are allowed (apply
  only).
- Read every path listed under `## Skills to load before work` before starting. They govern how
  you work.

## B. The working folder

Everything for issue N lives in `.australis/trabajo/<N>/` (absolute path given in your prompt).
It is ignored by git and disposable: GitHub holds the durable record.

| File | Written by | Read by | Language |
|---|---|---|---|
| `issue.md` | orchestrator | all | Spanish (the issue as written on GitHub) |
| `contexto.md` | orchestrator | all | key: value lines from `contexto.sh` |
| `baseline.md` | orchestrator | apply, verify | test failures that existed before any change |
| `explore.md` | explore | design, apply | English |
| `design.md` | design | apply, verify | English |
| `apply-progress.md` | apply | verify | English |
| `verify.md` | verify | orchestrator | English, plus the Spanish gate lines |

**The contract is the issue.** Its "Listo cuando" criteria are the acceptance criteria, verbatim.
Its "Restricciones técnicas" section, when present, binds every technical decision. Never edit
the issue, never reword or renumber its criteria.

If a file you require is missing, return `status: blocked` naming it. Do not improvise it.

## C. Project commands

Take commands only from `contexto.md`: `comando_test`, `comando_build`, `comando_lint`,
`comando_dev`, `gestor_paquetes`. A value of `ninguno` or empty means the project has none — never
invent one.

- **Strict TDD** applies when your prompt says `STRICT TDD MODE IS ACTIVE` (the project has a test
  runner). Apply and verify then load their strict-TDD module.
- **Without a runner**, evidence is a command, request or output you actually ran, recorded with
  what you ran and what it returned.
- Long commands (install, build, full suite): use a timeout of 600000.

## D. Branch rule

Your prompt names the default branch. Before writing anything, run `git branch --show-current`.
If it is the default branch, write nothing and return `status: blocked`: *"Estoy en la rama
principal y ahí no se escribe. Hace falta la rama del issue."* A guard hook also blocks commits
there; do not try to get around it.

## E. Language

- Working files (`explore.md`, `design.md`, `apply-progress.md`, `verify.md`), code, comments and
  commit messages: **English**.
- Anything the orchestrator shows the user (`executive_summary`, gate lines): **Spanish, plain,
  no jargon, rioplatense voseo** (*vos, tenés, podés*; never *tú, tienes*). The output style does
  not reach you, so the register has to come from here.

## F. Memory

If memory tools (`mem_search`, `mem_get_observation`) exist, you may search for earlier decisions
about this project. GitHub and the working folder are the source of truth: when memory disagrees,
follow them and note the difference under `risks`. Never block on memory.

## G. Return envelope

End with this, as text (never a tool call):

| Field | Content |
|---|---|
| `status` | `success`, `partial` or `blocked` |
| `executive_summary` | Spanish, plain, voseo — what the user may read |
| `artifacts` | Files written (working folder and source files) and commits made |
| `next_recommended` | The next phase, or `none` |
| `risks` | Risks, assumptions, deviations — or `None` |

Never put a diff, a stack trace or a file tree in `executive_summary`.
