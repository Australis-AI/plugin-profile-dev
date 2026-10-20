# Next.js + Supabase (on Vercel or Railway) — what to check

Most software built with AI assistants today is this stack, and the same failures recur in it.
Every item is a place to look, not a finding: confirm it in the code or in the database snapshot
before reporting it.

## seguridad

- **A secret the browser receives.** A `service_role` or `sb_secret_` key in a `NEXT_PUBLIC_*`
  variable, or imported by a file marked `"use client"`. CRÍTICO.
- **The secret key on a user request.** Server code that uses `service_role` or `sb_secret_`
  without checking who the user is: every query through it skips row-level security.
- **Tables open to the public key.** RLS off, or on without policies, in an exposed schema
  (snapshot: `tables`, `policies`, `grants`). RLS off with grants to `anon` means anyone with the
  public key reads and writes the table. CRÍTICO.
- **Policies that do not restrict.** `using (true)` on writes; `to anon` on private data;
  ownership checked against `user_metadata` in the JWT, which the user can edit.
- **`security definer` functions** without `set search_path` in `settings`, or executable by
  `anon` (snapshot: `functions`). They run with the owner's rights and skip RLS.
- **Views without `security_invoker`** over tables with RLS (snapshot: `views`). They run as
  their owner and return rows the caller should not see.
- **Public storage buckets** holding private files, or storage without policies.
- **Server actions and route handlers that do not check the user inside them.** A server action
  is a public POST endpoint: a check in the page or the layout does not protect it.
- **Authorization only in `middleware.ts`.** Middleware can be bypassed; the check belongs where
  the data is read or written.
- **`supabase.auth.getSession()` on the server to decide access.** It reads the cookie without
  verifying it. On the server, `getUser()` (or `getClaims()` in recent versions) verifies it.
- **Input that reaches the database without validation** at the boundary (no schema validation,
  such as zod, in actions and handlers).
- **No rate limit** on sign-in, sign-up, password reset or expensive endpoints.

## api — how the clients reach the data

- Map every path from a client to the data: supabase-js in the browser against tables or
  `rpc()`, server actions, route handlers (`app/api/**/route.ts`), edge functions. Note which
  checks and rules each path enforces.
- Business rules duplicated across paths, or living only in the browser (a total computed in a
  component and saved as is).
- The same capability reachable two ways with different checks.
- Whether a second client (a CLI, an MCP server, a mobile app, an integration, an AI agent) could
  use these capabilities without copying logic.

### When an intermediate API is worth proposing

Propose it when the evidence shows at least one of these:
- A second client exists or is planned: CLI, MCP server, mobile app, integration, agents.
- Business rules are duplicated across paths, or live in the browser.
- Writes need validation or side effects that RLS cannot express: several tables at once,
  external calls, an audit trail.
- `service_role` is spread through the code to get around RLS.

Do not propose it for one web client with simple per-user data. There, RLS plus checks inside
server actions is enough, and an API is one more layer to maintain. Say so when that is the case:
it is also a finding.

The shape to propose:
- **One API**, versioned, with a typed contract (OpenAPI or shared schemas), so a CLI or an MCP
  server is a thin client of it. Route handlers in the same Next.js app while there is one
  deployable; a separate service when several clients depend on it.
- **It acts as the user.** It forwards the user's JWT to Supabase, so RLS still decides. A
  personal token for a CLI or MCP is exchanged for a short-lived JWT of that user. `service_role`
  stays out of user requests: only system jobs use it, isolated.
- **Rules and validation at the API boundary**; the database keeps RLS as the last line.
- **Migration path:** move one capability at a time behind the API; remove the browser's direct
  access to a table only when nothing uses it anymore.

## arquitectura

- Supabase calls scattered through components and pages instead of one data layer per
  capability.
- Client components fetching data that could be read on the server.
- Types written by hand that drift from the database, instead of generated ones
  (`supabase gen types`).
- Schema (snapshot: `columns`, `constraints`, `indexes`): missing foreign keys; foreign keys
  without an index; rows that belong to someone without a `user_id`; money as `real` or `double
  precision`; `timestamp` without time zone; states as free text with no check or enum.

## operacion — Vercel or Railway

- **Drift:** the snapshot has tables, columns, policies or functions that no file in
  `supabase/migrations/` creates. The schema was changed from the dashboard and the repository
  can no longer rebuild the database.
- Preview deployments pointing at the production database.
- No staging: changes go from a branch straight onto production data.
- Backups: what the plan includes, and whether a restore was ever tried. Point-in-time recovery
  is a paid add-on.
- Environment variables set by hand per environment, with no `.env.example` listing them.
- Errors that only reach the browser console: nothing logged on the server.
- Railway: data written to the container's disk without a volume is lost on every deploy.
