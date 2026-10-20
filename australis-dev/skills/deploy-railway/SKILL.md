---
name: deploy-railway
description: "Publicar una app en Railway con GitHub Actions: la primera vez se arma una sola vez, y después cada integración a main publica sola, la haga quien la haga. Se usa desde /publicar cuando el README dice 'Deploy: railway'."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "1.0"
---

# Publish on Railway through GitHub Actions

Same rule as Vercel: production is deployed by a GitHub Actions workflow on every push to the
default branch. The Railway service is **not** connected to the repository, so the repository is
the only thing that decides what is published, and whoever integrates publishes.

Run every command here with the **Bash tool**. Read values from `.env.local` into a variable of
the same command, never print them.

## First time

Preconditions: the default branch has the app, and `.env.local` has the public Supabase values if
the app uses data. One step per message:

1. **Account and service.**
   > Vamos a publicar tu app en Railway. Entrá a **railway.com** y entrá con **GitHub**. Tocá
   > **New Project → Empty Project**. Adentro, tocá **Create → Empty Service** y ponele de nombre
   > `<slug>`. No conectes el repo: lo va a publicar GitHub.

   Say once: *"Railway cobra por uso desde el plan Hobby (unos 5 dólares por mes); no tiene plan
   gratis permanente."*
2. **Public variables**, when the app uses data:
   > En el servicio, abrí **Variables → Raw Editor** y pegá esto: (the two `NEXT_PUBLIC_SUPABASE_*`
   > lines from `.env.local`, only those two). Guardá con **Update Variables**.
3. **Domain:**
   > En **Settings → Networking**, tocá **Generate Domain** y copiame el dominio (termina en
   > `.up.railway.app`).
4. **Token and service.** Check `git check-ignore -q .env.local` (if it fails, stop: fix
   `.gitignore` first, as a small change). Append empty `RAILWAY_TOKEN=` and
   `RAILWAY_SERVICE_ID=` lines to `.env.local` if missing. Then:
   > Ahora un permiso para que GitHub pueda publicar. En el proyecto de Railway, abrí **Project
   > Settings → Tokens**, creá un token para el entorno **production** y pegalo en `.env.local`
   > después de `RAILWAY_TOKEN=`. Después abrí tu servicio: en la dirección del navegador, lo que
   > sigue a `/service/` es su identificador; pegalo después de `RAILWAY_SERVICE_ID=`. Guardá.
   > **No me pegues el token en el chat.** Avisame cuando esté.
5. **Secrets in GitHub:**
   ```bash
   printf '%s' "$RAILWAY_TOKEN" | gh secret set RAILWAY_TOKEN
   printf '%s' "$RAILWAY_SERVICE_ID" | gh secret set RAILWAY_SERVICE_ID
   ```
6. **The workflow**, on a branch `ci/deploy-railway`: `.github/workflows/deploy.yml` (below, with
   the real default branch), and the README lines `Deploy: railway` and the *Publicar* section.
   PR without an issue, integrate: it is part of the publish the user asked for. That merge is the
   first deploy.
7. **Watch it** as with Vercel: `gh run list --workflow deploy.yml --limit 1`, `gh run watch <id>
   --exit-status`; on failure, `gh run view <id> --log-failed` in plain words, fixed as a small
   change.
8. Write `App publicada: https://<domain>` in the README (branch `docs/published-url`, PR without
   an issue, integrate). If the app has sign-in, set Supabase's **Site URL** to it. Check that
   `curl -s -o /dev/null -w "%{http_code}" https://<domain>` answers 200.

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
    container: ghcr.io/railwayapp/cli:latest
    env:
      RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
    steps:
      - uses: actions/checkout@v4
      - run: railway up --service=${{ secrets.RAILWAY_SERVICE_ID }} --ci
```

Railway builds the app from the uploaded code: Next.js is detected, `npm run build` runs with the
service variables, and `next start` listens on the `PORT` Railway gives it.

## After the first time

`/publicar` reports from the last run, exactly as in
`${CLAUDE_PLUGIN_ROOT}/skills/deploy-vercel-supabase/SKILL.md` (*After the first time*). A new
variable goes in **Variables** in Railway, then `gh workflow run deploy.yml`.

**Railway gotcha:** a file written to the container's disk is lost on every deploy unless the
service has a **Volume**. Data lives in Supabase, never on that disk.
