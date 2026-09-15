# Supabase — setup, migrations and live checks

Everything that happens in the Supabase dashboard is done by the user in their browser, guided one
step at a time. You never ask for their database password, a secret key, or a service_role key.

## Connect a project (once per app)

Do this while something else runs (for example `npm install`), so the user does not wait twice.

1. Say:
   > Vamos a crear la base de datos de tu app. Entrá a **supabase.com**, tocá **Start your
   > project** y entrá con **Continue with GitHub**.
2. Then:
   > Tocá **New project**. Nombre: `<slug>`. Elegí una contraseña y **guardala vos** (no me la
   > pases). Región: la más cercana. Dejá tildado **Enable Data API**. Tocá **Create new project** y
   > esperá a que termine (un par de minutos).
3. Then:
   > Andá a **Project Settings → API Keys**. Copiame la **Project URL** y la **Publishable key**
   > (empieza con `sb_publishable_`). Las dos son públicas: está bien que me las pases.
4. If the user pastes a key starting with `sb_secret_`, or labelled service_role: tell them not to
   share it, ask them to rotate it in the dashboard (**API Keys → Secret keys → Roll**), and ask
   for the publishable one. Never write it anywhere.
5. Write `.env.local` (never committed):
   ```
   NEXT_PUBLIC_SUPABASE_URL=<url>
   NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=<publishable key>
   ```
   Keep `.env.example` with empty values. At `aprendiz`, teach `secretos` here.
6. Confirm the connection with the live check below against any table, or against
   `<url>/auth/v1/health` with the `apikey` header (expect HTTP 200).

**Limits of the free plan**, said once, when relevant:
- 2 active projects. On the third app: *"Tu plan gratis permite 2 proyectos activos: pausá o
  borrá uno viejo desde supabase.com antes de crear este."*
- A free project pauses after a week without use. If the live check cannot reach the project:
  *"Tu base se pausó por falta de uso. Entrá a supabase.com, abrí el proyecto y tocá Restore."*

## Sign-in issues

When an issue adds sign-in, before verifying:
> En Supabase andá a **Authentication → Sign In / Providers → Email** y apagá **Confirm email**.
> Así podés probar sin esperar mails (el servicio de mails gratis no llega a direcciones de afuera).

Record it in the PR's Risks: *"Email confirmation disabled for development; enable it and configure
SMTP before real users."* Also set **Authentication → URL Configuration → Site URL** to the
production domain once the app is published.

## Migrations

One file per issue that changes the schema: `supabase/migrations/<YYYYMMDDHHMMSS>_<name>.sql`.

**Template for every new table** — all four parts are mandatory:

```sql
create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  amount numeric(12, 2) not null check (amount > 0),
  description text not null default '',
  created_at timestamptz not null default now()
);

-- 1. Row-level security: without it the table is open to anyone with the public key.
alter table public.expenses enable row level security;

-- 2. Policies: each person sees and changes only their own rows.
create policy "expenses_select_own" on public.expenses
  for select to authenticated using (user_id = auth.uid());
create policy "expenses_insert_own" on public.expenses
  for insert to authenticated with check (user_id = auth.uid());
create policy "expenses_update_own" on public.expenses
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "expenses_delete_own" on public.expenses
  for delete to authenticated using (user_id = auth.uid());

-- 3. Grants: new tables are not exposed to the Data API without them.
grant select, insert, update, delete on public.expenses to authenticated;
```

For an app without sign-in, use `to anon` in policies and grants, and say in the PR's Risks that
the data is shared by everyone who opens the app.

A table without row-level security or without policies is a CRITICAL review finding.

**Applying it** (before verify, never after):

1. Copy the file to the clipboard:
   `powershell.exe -NoProfile -Command "Get-Content -Raw -Encoding UTF8 -LiteralPath '<path>' | Set-Clipboard"`
   (not `clip.exe`: it breaks accents).
2. Open `https://supabase.com/dashboard/project/<ref>/sql/new` (`<ref>` is the subdomain of the
   Project URL) and say:
   > Se abrió el editor SQL de Supabase. Pegá con **Ctrl+V** y tocá **Run**. No hace falta que me
   > avises: me doy cuenta solo.
3. Poll the live check every 5 seconds for up to 5 minutes. When it passes, continue. After 5
   minutes, ask once: *"¿Pudiste correrlo? Si apareció un error, copiámelo."*

At `dev`, the user may apply migrations with their own tooling; still run the live check.

## Live check (REST)

```bash
curl -s -w '\n%{http_code}' "$NEXT_PUBLIC_SUPABASE_URL/rest/v1/<table>?select=*&limit=1" \
  -H "apikey: $NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY" \
  -H "Authorization: Bearer $NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY"
```

Read the values from `.env.local` without printing them.

| Result | Meaning | Say |
|---|---|---|
| HTTP 200 (an empty list is fine: row-level security hides rows from the anonymous key) | Table exists and is exposed | continue |
| `"code":"PGRST205"` | The migration is not applied | wait, keep polling |
| `"code":"42501"` | The grant is missing | *"Falta dar permiso a la tabla: corrijo la migración."* Fix the file and apply again |
| No response or 5xx | Project paused or unreachable | the pause message above |

The live check is the evidence for criteria that depend on the database existing. Behaviour on
top of it is proven by the app's tests and by using the app at the result gate.
