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
- **Scale and where it is published** (`escala` and `deploy` in the context). They decide two
  judgments: whether the app needs an API, and what to check in its deployment. When either is
  `sin definir`:
  - Infer what you can: `vercel.json` or `.vercel/` → vercel; `railway.json` or `railway.toml`
    → railway; a `Dockerfile` with no platform file → probably own infrastructure.
  - At `dev`, confirm both in one message, with your inference as the default: *"¿Qué escala
    tiene esto: prototipo, producto o plataforma? Y se publica en <lo que inferí>, ¿no?"*
  - At `aprendiz`, ask only the scale, in plain words (as in discovery), and use the inference
    for the deployment.
  - Say in the report that they were missing; writing the README lines becomes a chico finding.
- Ensure `.australis/.gitignore` contains `*`. Everything the audit writes goes to
  `.australis/auditoria/`.

## 1. The database — read access that stays

When the project uses Supabase (`@supabase/*` in `package.json`, or a `supabase/` folder), audit
the live database, not only the migrations: changes made from the dashboard never reach the
repository, and that difference is itself a finding.

The access is set up once and stays in the project: two variables in `.env.local`, which git
ignores, read by `${CLAUDE_PLUGIN_ROOT}/scripts/supabase-lectura.mjs`. The script talks to the
Supabase Management API with `read_only: true`, so every query runs as Supabase's read-only
database user, and it refuses anything that is not a read.

**Route 1 — the read token (the main one).**
1. Check `git check-ignore -q .env.local`. If it fails, the token cannot go there: that is a
   crítico finding of its own, and you take route 2.
2. If `SUPABASE_ACCESS_TOKEN` is already in `.env.local`, skip to 4.
3. Append `SUPABASE_PROJECT_REF=<ref>` (the subdomain of `NEXT_PUBLIC_SUPABASE_URL`; read it
   without printing anything else from that file) and an empty `SUPABASE_ACCESS_TOKEN=` to
   `.env.local`, then say:
   > Para auditar la base necesito leerla: cómo está armada, sus permisos y sus funciones. Lo
   > dejamos configurado una vez y queda para cuando haga falta.
   > 1. Entrá a **supabase.com/dashboard/account/tokens** con la cuenta dueña del proyecto.
   > 2. Tocá **Generate new token**, nombre `lectura-<proyecto>`, y copialo (empieza con `sbp_`).
   > 3. Abrí `.env.local` en tu proyecto, pegalo después de `SUPABASE_ACCESS_TOKEN=` y guardá.
   >    **No me lo pegues en el chat.**
   >
   > Yo lo uso solo para leer. Ojo: ese token abre todos los proyectos de esa cuenta, así que si
   > el proyecto es de un cliente, que lo genere el cliente desde su cuenta. Si no podés
   > generarlo, decime y vamos por otro camino.

   At `dev`, add the technical line: *"Es un personal access token de la Management API; las
   consultas van con `read_only: true` (rol `supabase_read_only_user`). La anon o publishable
   key no sirve para esto: no lee el catálogo."* **Wait** for it.
4. Run `node "${CLAUDE_PLUGIN_ROOT}/scripts/supabase-lectura.mjs" --file
   "${CLAUDE_PLUGIN_ROOT}/skills/auditar/references/base-supabase.sql"` from the project root.
   HTTP 401 or 403: the token is wrong or belongs to another account; say it in one line and
   offer route 2.

**Route 2 — when there is no token.** In this order, the first that works:
- A Supabase MCP connected in this session: run the snapshot query with its SQL tool, and its
  security and performance advisors when it offers them.
- The SQL editor, the same way migrations are applied in
  `${CLAUDE_PLUGIN_ROOT}/skills/stack-australis/references/supabase.md`: copy the snapshot query
  to the clipboard, open `https://supabase.com/dashboard/project/<ref>/sql/new` and say:
  > Se abrió el editor SQL de Supabase: pegá con **Ctrl+V**, tocá **Run** y copiame el resultado
  > (es una sola celda). No lee ningún dato, solo cómo está armada la base.
- Nothing: continue with `supabase/migrations/` only, and say in the report that the database
  was read from the repository, not live.

Save the snapshot to `.australis/auditoria/<AAAA-MM-DD>-base.json` and pass its path to the
auditors. Never ask for the database password, a `service_role` or an `sb_secret_` key.

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
| api | How each client reaches the data and where the rules live; whether a second client (CLI, MCP, mobile, integration) could use the same capabilities; whether an intermediate API is worth it, starting from the scale |
| arquitectura | Structure that hides what the system does, business rules mixed with database or UI, the database model, patterns used inconsistently, a simpler design for the same result |
| tests | Rules, permissions or data integrity with no test, tests that prove nothing, a slow or flaky suite, no test runner |
| mantenibilidad | Duplication, dead code, oversized files and functions, outdated or vulnerable dependencies |
| operacion | How to run, test and publish undocumented, schema drift between the live database and the migrations, how a merge reaches production on Vercel, Railway or own infrastructure, environments, backups, errors swallowed or never logged |

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
