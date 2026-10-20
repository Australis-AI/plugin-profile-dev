---
name: deploy-vercel-supabase
description: "Publicar una app del stack Australis en Vercel con GitHub Actions: la primera vez se arma una sola vez, y después cada integración a main publica sola, la haga quien la haga. Se usa desde /publicar."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "2.0"
---

# Publish on Vercel through GitHub Actions

Production is deployed by a GitHub Actions workflow on every push to the default branch. Vercel's
own Git integration stays off: with it, Vercel only builds commits whose author is a member of the
Vercel team (on Pro, a paid seat per person; on Hobby, only the owner), so a merge by anyone else
stays unpublished. With Actions, whoever integrates publishes. Production always comes from
`main`; nothing is deployed from the local machine.

Run every command here with the **Bash tool**. Read values from `.env.local` into a variable of
the same command, never print them:
`VERCEL_TOKEN="$(sed -n 's/^VERCEL_TOKEN=//p' .env.local | tr -d '\r' | head -1)"`.

## First time

Preconditions: the default branch has the app (at least issue #1 integrated), and `.env.local`
has the two public Supabase values if the app uses data. One step per message:

1. **Account.**
   > Vamos a publicar tu app. Entrá a **vercel.com**, tocá **Sign Up** y elegí **Continue with
   > GitHub**. Si te pregunta el plan, elegí **Hobby**.
2. **Token.** Check `git check-ignore -q .env.local` (if it fails, stop: add `.env*` and
   `!.env.example` to `.gitignore` first, as a small change). Append an empty `VERCEL_TOKEN=` line
   to `.env.local` if it is not there. Then:
   > Ahora un permiso para que GitHub pueda publicar por vos. Entrá a
   > **vercel.com/account/tokens**, tocá **Create**, nombre `github-actions-<slug>`, y copiá el
   > token. Abrí el archivo `.env.local` de tu proyecto, pegalo después de `VERCEL_TOKEN=` y
   > guardá. **No me lo pegues en el chat.** Avisame cuando esté.

   Check the value is not empty without printing it. If the user pastes it in the chat anyway:
   ask them to delete that token in Vercel and create another, and never write the pasted one.
3. **Project.** With the token from `.env.local`:
   ```bash
   npx --yes vercel@latest project add <slug> --token "$VERCEL_TOKEN"     # "already exists" is fine
   npx --yes vercel@latest link --yes --project <slug> --token "$VERCEL_TOKEN"
   npx --yes vercel@latest git disconnect --yes --token "$VERCEL_TOKEN"   # "not connected" is fine
   ```
   `link` writes `.vercel/project.json` with `orgId` and `projectId`. `.vercel` must be in
   `.gitignore` (the Next.js template has it; add it otherwise).
4. **Public variables**, when the app uses data. For each of `NEXT_PUBLIC_SUPABASE_URL` and
   `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, from `.env.local`:
   `printf '%s' "$VALUE" | npx --yes vercel@latest env add <NAME> production --token "$VERCEL_TOKEN"`.
   If it already exists, leave it.
5. **Secrets in GitHub:**
   ```bash
   printf '%s' "$VERCEL_TOKEN" | gh secret set VERCEL_TOKEN
   gh secret set VERCEL_ORG_ID --body "<orgId>"
   gh secret set VERCEL_PROJECT_ID --body "<projectId>"
   ```
6. **The workflow**, on a branch `ci/deploy-vercel`: `.github/workflows/deploy.yml` (below, with
   the real default branch), `vercel.json` with `"git": { "deploymentEnabled": false }` (merge
   the key if the file exists), and the README lines `Deploy: vercel` and the *Publicar* section.
   Commit, push, open its PR without an issue and integrate it: it is part of the publish the user
   asked for. That merge is the first deploy.
7. **Watch it:** `gh run list --workflow deploy.yml --limit 1 --json databaseId,status,conclusion`,
   then `gh run watch <id> --exit-status`. On failure, read `gh run view <id> --log-failed`, say
   what failed in plain words, and fix it as a small change.
8. **Domain.**
   > Ya está publicada. Entrá a tu proyecto en **vercel.com**, abrí **Domains** y copiame el
   > dominio que termina en `.vercel.app`.

   Write it in the README as `App publicada: https://<domain>` (branch `docs/published-url`, PR
   without an issue, integrate). If the app has sign-in: *"En Supabase, **Authentication → URL
   Configuration → Site URL**, poné `https://<domain>`."*
9. **Check:** `curl -s -o /dev/null -w "%{http_code}" https://<domain>` must answer 200. Tell the
   user to open it from their phone. At `aprendiz`, teach `deploy` here.
10. Say once: *"El plan gratis de Vercel es para uso personal. Si la app va a ser de un negocio o
    va a cobrar, hay que pasar al plan Pro. Con este armado, igual no hace falta pagar un lugar
    por cada persona que integra."*

**Already on Vercel's Git integration:** same steps from 2, linking to the existing project name.
`git disconnect` and `vercel.json` stop the old automatic deploys.

## The workflow

```yaml
name: Deploy

on:
  push:
    branches: [main]   # the repository's default branch
  workflow_dispatch:

concurrency:
  group: deploy-production
  cancel-in-progress: false

jobs:
  production:
    runs-on: ubuntu-latest
    env:
      VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
      VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: npm install --global vercel@latest
      - run: vercel pull --yes --environment=production --token=${{ secrets.VERCEL_TOKEN }}
      - run: vercel build --prod --token=${{ secrets.VERCEL_TOKEN }}
      - run: vercel deploy --prebuilt --prod --token=${{ secrets.VERCEL_TOKEN }}
```

It does not run the tests: what reaches `main` was already tested on the branch (orchestrator,
*Integrating*). The build runs here because production is built from the merged commit.

## After the first time

- Integrating an issue publishes it: the result gate calls the option *"integrar (también
  publica)"*.
- `/publicar` only reports, from the last run of the workflow on the default branch:

```bash
gh run list --workflow deploy.yml --branch <default> --limit 1 \
  --json databaseId,status,conclusion,headSha
```

| State | Say |
|---|---|
| `completed` + `success`, and `headSha` is the head of `main` | *"Tu app está publicada y al día: https://<domain>"* |
| `completed` + `success` on an older sha | *"Se está publicando lo último; en un par de minutos está."* |
| `in_progress`, `queued` | *"Se está publicando ahora."* |
| `completed` + `failure` | *"La última publicación falló."* Read `gh run view <id> --log-failed`, explain it in plain words, and fix it as a small change |
| No runs | Run the first time |

## Environment variables later

A new variable: `printf '%s' "$VALUE" | npx --yes vercel@latest env add <NAME> production --token
"$VERCEL_TOKEN"`, then `gh workflow run deploy.yml` to publish with it. A variable without
`NEXT_PUBLIC_` stays on the server. Never a `service_role` or `sb_secret_` key: the stack has no
server-side admin access.
