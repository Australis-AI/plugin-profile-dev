-- Australis audit: read-only snapshot of a Supabase database.
-- Schema, permissions and settings only: it never reads a row of user data.
-- One query and one JSON result, so it can run from the Supabase SQL editor and be copied whole.
with sys(name) as (
  values ('pg_catalog'), ('information_schema'), ('pg_toast'), ('auth'), ('storage'),
         ('extensions'), ('graphql'), ('graphql_public'), ('realtime'), ('_realtime'),
         ('supabase_functions'), ('supabase_migrations'), ('vault'), ('pgsodium'),
         ('pgsodium_masks'), ('net'), ('cron'), ('pgbouncer'), ('_analytics'), ('pgtle')
)
select json_build_object(
  'tables', (
    select json_agg(json_build_object(
      'table', n.nspname || '.' || c.relname,
      'rls', c.relrowsecurity,
      'rls_forced', c.relforcerowsecurity,
      'rows_estimate', c.reltuples::bigint
    ) order by n.nspname, c.relname)
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where c.relkind in ('r', 'p')
      and n.nspname not in (select name from sys)
  ),
  'columns', (
    select json_agg(json_build_object(
      'table', table_schema || '.' || table_name,
      'column', column_name,
      'type', data_type,
      'nullable', is_nullable,
      'default', column_default
    ) order by table_schema, table_name, ordinal_position)
    from information_schema.columns
    where table_schema not in (select name from sys)
  ),
  'constraints', (
    select json_agg(json_build_object(
      'table', conrelid::regclass::text,
      'name', conname,
      'definition', pg_get_constraintdef(oid)
    ) order by conrelid::regclass::text, conname)
    from pg_constraint
    where contype in ('p', 'f', 'u', 'c')
      and conrelid <> 0
      and connamespace::regnamespace::text not in (select name from sys)
  ),
  'indexes', (
    select json_agg(json_build_object(
      'table', schemaname || '.' || tablename,
      'definition', indexdef
    ) order by schemaname, tablename, indexname)
    from pg_indexes
    where schemaname not in (select name from sys)
  ),
  'policies', (
    select json_agg(json_build_object(
      'table', schemaname || '.' || tablename,
      'name', policyname,
      'permissive', permissive,
      'roles', roles,
      'command', cmd,
      'using', qual,
      'with_check', with_check
    ) order by schemaname, tablename, policyname)
    from pg_policies
    where schemaname not in ('pg_catalog', 'information_schema')
  ),
  'grants', (
    select json_agg(g order by g.table_name, g.grantee)
    from (
      select table_schema || '.' || table_name as table_name,
             grantee,
             string_agg(privilege_type, ',' order by privilege_type) as privileges
      from information_schema.role_table_grants
      where grantee in ('anon', 'authenticated')
        and table_schema not in (select name from sys)
      group by table_schema, table_name, grantee
    ) g
  ),
  'functions', (
    select json_agg(json_build_object(
      'function', n.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')',
      'security_definer', p.prosecdef,
      'settings', p.proconfig,
      'anon_can_execute', has_function_privilege('anon', p.oid, 'execute'),
      'authenticated_can_execute', has_function_privilege('authenticated', p.oid, 'execute')
    ) order by n.nspname, p.proname)
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname not in (select name from sys)
      and not exists (
        select 1 from pg_depend d
        where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e'
      )
  ),
  'views', (
    select json_agg(json_build_object(
      'view', n.nspname || '.' || c.relname,
      'materialized', c.relkind = 'm',
      'security_invoker', exists (
        select 1 from unnest(c.reloptions) as o(opt)
        where o.opt in ('security_invoker=true', 'security_invoker=on', 'security_invoker=1')
      )
    ) order by n.nspname, c.relname)
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where c.relkind in ('v', 'm')
      and n.nspname not in (select name from sys)
  ),
  'triggers', (
    select json_agg(json_build_object(
      'table', event_object_schema || '.' || event_object_table,
      'trigger', trigger_name,
      'timing', action_timing,
      'event', event_manipulation,
      'action', action_statement
    ) order by event_object_schema, event_object_table, trigger_name)
    from information_schema.triggers
    where trigger_schema not in (select name from sys)
  ),
  'storage_buckets', (
    select json_agg(json_build_object('bucket', id, 'public', public) order by id)
    from storage.buckets
  ),
  'extensions', (
    select json_agg(json_build_object('name', extname, 'version', extversion) order by extname)
    from pg_extension
  )
) as snapshot;
