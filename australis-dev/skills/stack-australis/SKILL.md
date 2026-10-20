---
name: stack-australis
description: "El stack fijo de Australis para apps nuevas: Next.js, TypeScript, Supabase y Vitest, con su estructura, datos seguros y pruebas. Se usa cuando el README del proyecto dice 'Stack: australis'."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "1.0"
---

# The Australis stack

Applies when the project's README has the line `Stack: australis`. It overrides the generic
architecture section of dev-context for structure. A technical constraint written in the issue
still overrides this reference.

| Piece | Choice | Why, in one line for the user |
|---|---|---|
| Framework | Next.js 16, App Router, TypeScript | *"Es la forma más usada de hacer apps web hoy: hay mucha ayuda y se publica fácil."* |
| Styling | Tailwind CSS | *"Los estilos van junto a cada pantalla, sin archivos sueltos."* |
| Data and sign-in | Supabase (Postgres + Auth) | *"Guarda tus datos en una base real y maneja las cuentas de usuario."* |
| Tests | Vitest + Testing Library | *"Pruebas rápidas que comprueban solas que la app hace lo acordado."* |
| Deploy | Vercel by default; Railway or own infrastructure (Dokploy) when chosen. Always published by GitHub Actions from `main` | *"Cada vez que integramos un paso, se publica solo, lo integre quien lo integre."* |

## Structure

```
app/                          routes (pages and layouts only; thin)
  <route>/page.tsx
features/<capability>/        one folder per capability the user sees
  components/                 UI for this capability
  data.ts                     all Supabase access for this capability
  <logic>.ts                  pure logic (calculations, validation)
  *.test.ts(x)                tests next to what they test
lib/supabase.ts               the single Supabase client (created by the scaffold)
supabase/migrations/          SQL migrations, in order
```

- Folder names say what the app does: `features/expenses`, `features/monthly-total`.
- Pages compose feature components; they do not talk to Supabase directly.
- Components never import `@supabase/supabase-js`; they call functions from `data.ts`.

## Data rules

- **Client:** only `lib/supabase.ts`, with `NEXT_PUBLIC_SUPABASE_URL` and
  `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`. The publishable key is public by design.
- **Never** a secret key (`sb_secret_…`) or `service_role` in the app. There is no server-side
  admin access in this stack.
- **Every table has row-level security with policies**, and every row that belongs to someone has
  `user_id uuid not null default auth.uid() references auth.users`.
- **Migrations are additive:** add tables, columns, policies. Renaming or dropping goes in a later
  issue, once no code uses the old shape.
- Setup, migrations and the live checks are in
  `${CLAUDE_PLUGIN_ROOT}/skills/stack-australis/references/supabase.md`.

## Escala — how the browser reaches the data

The README line `Escala:` (written in issue #1, from discovery) decides it.

- **prototipo, producto:** as described above. Components call `features/<capability>/data.ts`,
  which uses the Supabase client; row-level security protects every row.
- **plataforma:** an API from the first issue that saves data, so a CLI, an MCP server, a mobile
  app or another system can later use the same capabilities without copying the rules.

```
app/api/v1/<capability>/route.ts   the API: checks the user, validates, applies the rules
features/<capability>/data.ts      calls the API with fetch, never Supabase directly
features/<capability>/<logic>.ts   the rules, pure, used by the API
lib/supabase-as-user.ts            a Supabase client for one request, acting as its user
```

Rules for the API:
- **It acts as the user.** `data.ts` sends the user's access token (from the browser's Supabase
  session) as `Authorization: Bearer`. The route builds its Supabase client with the publishable
  key and that token, so row-level security still decides. No secret key, no `service_role`.
- **It checks the user inside the route** with `supabase.auth.getUser(token)`, never only in
  middleware, and answers 401 without a valid user.
- **It validates every input** with a schema (zod) and answers 400 saying what is wrong.
- **Versioned and typed:** paths start with `/api/v1/`; each route exports its input and output
  types, so a later CLI or MCP server reuses them.
- Essential tests: each route's authorization (no user → 401; another user's row → 404) and its
  validation, plus the rules in `<logic>.ts`.

```ts
// lib/supabase-as-user.ts
import { createClient } from "@supabase/supabase-js";

export function supabaseAsUser(accessToken: string) {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      global: { headers: { Authorization: `Bearer ${accessToken}` } },
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );
}
```

Moving a *producto* to *plataforma* later is an epic of its own: one capability per issue, moved
behind the API; the browser's direct access to a table is removed only when nothing uses it.

## Testing rules

- Only essential tests (`${CLAUDE_PLUGIN_ROOT}/skills/sdd-apply/essential-tests.md`): permissions,
  data integrity, business rules, fixed bugs.
- Pure logic (`features/<capability>/<logic>.ts`): unit tests with no mocks. This is where most
  tests live.
- Components: no tests. What they show is checked with the app running at the gate. Exception: a
  component that enforces a rule (it blocks a double payment, it hides an action from a role) gets
  a test for that rule, with Testing Library.
- Data functions and row-level security: checked against the real project through the live REST
  check, never from unit tests.
- Commands: `npm test` (all), `npm run lint`, `npm run build`.

## Running the app

- `npm run dev -- --hostname 127.0.0.1`, started in the background by the orchestrator; the URL is
  the `Local:` line of its output.
- Stop the server before `npm install` and when the result gate closes: on Windows a running dev
  server locks files.

## Issue #1 — "Base del proyecto"

Run by the orchestrator in the main thread, on branch `feat/1-project-base`:

1. If the folder is under OneDrive: at `aprendiz`, stop and move to `%USERPROFILE%\apps` (npm
   fails inside OneDrive); at `dev`, warn in one line and continue.
2. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold-web.sh" <slug>` with a timeout of 600000. It
   prints `SCAFFOLD_OK`. If it fails during dependencies, run it again: it resumes.
3. Run `npm test`, `npm run lint`, `npm run build`. All must pass.
   Then add the discovery's two kit lines to the README, next to the `Stack:` line:
   `Escala: <prototipo|producto|plataforma>` and `Deploy: <vercel|railway|dokploy>`.
4. Connect Supabase (reference above) if the epic needs saved data; otherwise leave
   `.env.example` for later.
5. Commit in work units (`chore: scaffold next.js app`, `test: add vitest setup`), push, then
   continue with review, PR and the result gate as for any issue. Evidence for criterion 1 is the
   dev server answering on its URL.
