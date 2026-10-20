---
name: auditar
description: "Auditar el software que ya existe: qué está mal, qué va a doler cuando crezca y qué conviene hacer de otra forma; lo que el usuario elige se vuelve issues. Trigger: auditá, auditoría, qué se puede mejorar, revisá el proyecto entero, deuda técnica, qué harías distinto."
license: MIT
metadata:
  author: australis-ai
  version: "1.0"
---

# Audit

An audit looks at the code that already exists, not at a change, and answers three questions:
what is wrong, what will hurt as the project grows, and what would be better done another way.
It never edits code. What the user picks enters the method as issues.

Prompt and finding format: `${CLAUDE_PLUGIN_ROOT}/skills/auditar/references/prompts.md`.

## 0. Context and scope

- Run the context script (orchestrator Step 0). The audit works on any branch and writes nothing
  to the repository.
- Scope: the area in the arguments (a folder, a feature), or the whole repository. A dimension
  name in the arguments (*seguridad*, *tests*, *arquitectura*, *mantenibilidad*, *operación*)
  limits the audit to that dimension.
- `repo: no` or no source files: say there is nothing to audit yet and stop.
- Ensure `.australis/.gitignore` contains `*`. The report goes to
  `.australis/auditoria/<AAAA-MM-DD>.md`.

## 1. Auditors — in parallel

Launch one `australis-dev:auditor` per dimension, all in the same message, model `sonnet`, with
the auditor prompt. Each gets the scope, its dimension, the context output, and under
`## Skills to load before work` the path `${CLAUDE_PLUGIN_ROOT}/skills/dev-context/SKILL.md`, plus
`${CLAUDE_PLUGIN_ROOT}/skills/stack-australis/SKILL.md` when the context says `stack: australis`.

| Dimension | Looks for |
|---|---|
| arquitectura | Structure that hides what the system does, business rules mixed with database or UI, patterns used inconsistently, a simpler design for the same result |
| seguridad | Secrets in code or in git history, missing authorization, row-level security off or without policy, user input reaching queries or HTML unescaped, public writes |
| tests | Behaviour with no test, tests that prove nothing, a slow or flaky suite, no test runner |
| mantenibilidad | Duplication, dead code, oversized files and functions, outdated or vulnerable dependencies |
| operacion | How to run, test and publish undocumented, environment variables without `.env.example`, no CI, errors swallowed or never logged, saved data without backup |

Only the `tests` auditor runs the test command, once, timed. The others never run tests or
builds.

## 2. Confirm — nothing unconfirmed reaches the user

For each finding, confirm it yourself before it enters the report: open the cited code and check
the claim, or run the read-only command that shows it. Discard what you cannot confirm and keep
the count. Merge findings that two auditors reported from different angles.

## 3. Rank

Each confirmed finding keeps the auditor's severity unless confirming it changed it, and gets a
size:

- **chico** when fixing it passes the small-change entry test of
  `${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/SKILL.md`;
- **grande** otherwise.

Order: críticos first; then high impact and chico; then high impact and grande; then the rest.

## 4. Report — gate

Write `.australis/auditoria/<AAAA-MM-DD>.md` in Spanish: every confirmed finding with location,
evidence, impact, proposal and size, and the number discarded.

Show the user, in Spanish:

1. One line: how many findings were confirmed, how many are críticos, how many were discarded.
2. The findings, numbered, at most 10 at `dev` and 5 at `aprendiz`:
   `N. [crítico|alto|medio|bajo] <qué pasa, en palabras del usuario> → <qué propongo> (chico|grande)`
   - `dev`: add the file and, for a "do it another way" finding, the rejected current approach.
   - `aprendiz`: no paths, no jargon; say what happens to the user or the business.
3. Close: *"¿Cuáles hacemos? Decime los números, «los críticos» o «ninguno»."* **Stop and wait.**

## 5. What the user picks enters the method

- If a crítico about security is left out, say once, in one line, why it should go first.
- **One chico finding:** a **Small change** of the orchestrator, from its Define gate, with the
  finding as the draft.
- **More than one, or any grande:** an epic *"Mejoras: <área o proyecto>"*, drafted with
  `${CLAUDE_PLUGIN_ROOT}/skills/epica-issues/SKILL.md`, one issue per finding, críticos first.
  Chico issues get the label `cambio-chico`, so they are built in the light lane. A finding that
  changes structure without changing behaviour uses the *"Sin cambio de comportamiento"*
  criterion. Then follow **New work** step 4 of the orchestrator: the epic gate, creation, and the
  first issue.
- **Ninguno:** say that the report stays in `.australis/auditoria/`, on this computer only.

## Rules

- Read-only until the user picks: no edits, installs, migrations, commits or pushes, in this
  thread or in the auditors.
- A secret found: never print its value, only where it is. Say it must be rotated, not just
  deleted: it stays in git history.
- Never paste auditor output, a diff or a file tree to the user.
