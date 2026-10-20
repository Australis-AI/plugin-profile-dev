---
name: auditar
description: "Auditar el software que ya existe: qué está mal, qué va a doler cuando crezca y qué conviene hacer de otra forma, incluida la base de datos y si hace falta una API; lo que el usuario elige se vuelve issues. Trigger: auditá, auditoría, qué se puede mejorar, revisá el proyecto entero, deuda técnica, qué harías distinto."
license: MIT
metadata:
  author: australis-ai
  version: "1.1"
---

# Audit

An audit looks at the software that already exists, not at a change, and answers three
questions: what is wrong, what will hurt as the project grows, and what would be better done
another way. It never edits code. What the user picks enters the method as issues.

References:
- Auditor prompt and finding format: `${CLAUDE_PLUGIN_ROOT}/skills/auditar/references/prompts.md`
- Next.js + Supabase checks: `${CLAUDE_PLUGIN_ROOT}/skills/auditar/references/nextjs-supabase.md`
- Database snapshot query: `${CLAUDE_PLUGIN_ROOT}/skills/auditar/references/base-supabase.sql`

## 0. Context and scope

- Run the context script (orchestrator Step 0). The audit works on any branch and writes nothing
  to the repository.
- Scope: the area in the arguments (a folder, a feature), or the whole repository. A dimension
  name in the arguments (*seguridad*, *api*, *tests*, *arquitectura*, *mantenibilidad*,
  *operación*) limits the audit to that dimension.
- `repo: no` or no source files: say there is nothing to audit yet and stop.
- Stack: when `package.json` lists `next` and `@supabase/supabase-js` or `@supabase/ssr`, every
  auditor also gets the Next.js + Supabase checks.
- Ensure `.australis/.gitignore` contains `*`. Everything the audit writes goes to
  `.australis/auditoria/`.

## 1. The database — read it live

When the project uses Supabase (`@supabase/*` in `package.json`, or a `supabase/` folder), audit
the live database, not only the migrations: changes made from the dashboard never reach the
repository, and that difference is itself a finding. Read the schema with the first route that
works. Read-only and schema only: never a row of user data.

1. **A Supabase MCP is connected in this session:** run the snapshot query with its SQL tool, and
   its security and performance advisors when it offers them.
2. **Otherwise, the SQL editor**, the same way migrations are applied in
   `${CLAUDE_PLUGIN_ROOT}/skills/stack-australis/references/supabase.md`: copy the snapshot query to
   the clipboard, open `https://supabase.com/dashboard/project/<ref>/sql/new` (`<ref>` is the
   subdomain of the project URL, usually `NEXT_PUBLIC_SUPABASE_URL` in `.env.local`; read it
   without printing anything else from that file) and say:
   > Para auditar la base necesito ver cómo está armada: tablas, permisos y funciones, sin leer
   > ningún dato. Se abrió el editor SQL de Supabase: pegá con **Ctrl+V**, tocá **Run** y copiame
   > el resultado (es una sola celda). Si preferís que siga sin la base, decime «sin la base».

   At `dev`, add one line: *"Si tenés el MCP de Supabase, conectalo en modo solo lectura y lo
   leo yo."* **Wait** for the result.
3. **No access, or the user prefers without it:** continue with `supabase/migrations/` only, and
   say in the report that the database was read from the repository, not live.

Save what came back to `.australis/auditoria/<AAAA-MM-DD>-base.json` and pass its path to the
auditors. Never ask for the database password or a secret key.

## 2. Auditors — in parallel

Launch one `australis-dev:auditor` per dimension, all in the same message, model `sonnet`, with
the auditor prompt. Each gets the scope, its dimension, the context output, the database snapshot
path when there is one, and under `## Skills to load before work` the path
`${CLAUDE_PLUGIN_ROOT}/skills/dev-context/SKILL.md`, plus the Next.js + Supabase checks when the
stack matches, plus `${CLAUDE_PLUGIN_ROOT}/skills/stack-australis/SKILL.md` when the context says
`stack: australis`.

| Dimension | Looks for |
|---|---|
| seguridad | Secrets in code or in git history, missing authorization, row-level security off or without policy, unescaped input, public writes |
| api | How each client reaches the data and where the rules live; whether a second client (CLI, MCP, mobile, integration) could use the same capabilities; whether an intermediate API is worth it |
| arquitectura | Structure that hides what the system does, business rules mixed with database or UI, the database model, patterns used inconsistently, a simpler design for the same result |
| tests | Rules, permissions or data integrity with no test, tests that prove nothing, a slow or flaky suite, no test runner |
| mantenibilidad | Duplication, dead code, oversized files and functions, outdated or vulnerable dependencies |
| operacion | How to run, test and publish undocumented, schema drift between the live database and the migrations, environments, backups, errors swallowed or never logged |

Only the `tests` auditor runs the test command, once, timed. The others never run tests or
builds.

## 3. Confirm — nothing unconfirmed reaches the user

For each finding, confirm it yourself before it enters the report: open the cited code or the
snapshot entry and check the claim, or run the read-only command that shows it. Discard what you
cannot confirm and keep the count. Merge findings that two auditors reported from different
angles.

## 4. Rank

Each confirmed finding keeps the auditor's severity unless confirming it changed it, and gets a
size:

- **chico** when fixing it passes the small-change entry test of
  `${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/SKILL.md`;
- **grande** otherwise.

Order: críticos first; then high impact and chico; then high impact and grande; then the rest.

## 5. Report — gate

Write `.australis/auditoria/<AAAA-MM-DD>.md` in Spanish with the format in the prompts reference:
every confirmed finding, and the number discarded.

Show the user, in Spanish:

1. One line: how many findings were confirmed, how many are críticos, how many were discarded,
   and whether the database was read live.
2. The findings, numbered, at most 10 at `dev` and 5 at `aprendiz`:
   `N. [crítico|alto|medio|bajo] <qué pasa> → <qué propongo> (chico|grande)`
   - **`dev`:** technical depth. Each finding names the mechanism (why it fails, not only that
     it does), the location (`path:line` or the snapshot entry), and for a "do it another way"
     finding the current approach, the alternative and its cost. The API finding, when there is
     one, says which evidence makes the API worth it or not.
   - **`aprendiz`:** no paths, no jargon. Say what happens to the user or the business, and what
     changes after the fix.
3. Close: *"¿Cuáles hacemos? Decime los números, «los críticos» o «ninguno»."* **Stop and wait.**

## 6. What the user picks enters the method

- If a crítico about security is left out, say once, in one line, why it should go first.
- **One chico finding:** a **Small change** of the orchestrator, from its Define gate, with the
  finding as the draft.
- **More than one, or any grande:** an epic *"Mejoras: <área o proyecto>"*, drafted with
  `${CLAUDE_PLUGIN_ROOT}/skills/epica-issues/SKILL.md`, one issue per finding, críticos first.
  Chico issues get the label `cambio-chico`, so they are built in the light lane. A finding that
  changes structure without changing behaviour uses the *"Sin cambio de comportamiento"*
  criterion. An intermediate API is an epic of its own, one capability per issue. Then follow
  **New work** step 4 of the orchestrator: the epic gate, creation, and the first issue.
- **Ninguno:** say that the report stays in `.australis/auditoria/`, on this computer only.

## Rules

- Read-only until the user picks: no edits, installs, migrations, commits or pushes, in this
  thread or in the auditors. Database access is schema only.
- A secret found: never print its value, only where it is. Say it must be rotated, not just
  deleted: it stays in git history.
- Never paste auditor output, a diff, the snapshot or a file tree to the user.
