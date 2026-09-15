---
name: deploy-vercel-supabase
description: "Publicar una app del stack Australis en Vercel conectada a GitHub: import guiado una vez, y después cada merge a main publica solo. Se usa desde /publicar."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "1.0"
---

# Publish on Vercel (clients, Australis stack)

Vercel is connected to the GitHub repository once, in the browser, by the user. From then on every
merge to the default branch publishes production by itself. **You never run a deploy command**:
no Vercel CLI, no tokens, nothing uploaded from the local machine. Production always comes from
`main`.

## First time: guided import

Preconditions: the default branch has the app (at least issue #1 integrated), and `.env.local`
has the two public Supabase values if the app uses data. Do this in one guided sequence, one step
per message:

1. > Vamos a publicar tu app. Entrá a **vercel.com**, tocá **Sign Up** y elegí **Continue with
   > GitHub**. Si te pregunta el plan, elegí **Hobby**.
2. > Tocá **Add New… → Project**. En la lista de repos, buscá **<repo>** y tocá **Import**. Si no
   > aparece, tocá **Configure GitHub App** y dale acceso a ese repo.
3. > Antes de publicar, abrí **Environment Variables** y cargá estas dos (son públicas):
   > `NEXT_PUBLIC_SUPABASE_URL` = `<url>` y `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` = `<publishable key>`.
   > Después tocá **Deploy** y esperá a que termine.

   Read the values from `.env.local` and show them so the user can paste them. Show only these two
   public values, never anything else from that file.
4. > Cuando termine, copiame el dominio de tu app: aparece en **Domains** y termina en
   > `.vercel.app`.
5. Write the domain in the README as `App publicada: https://<domain>` (commit it on a
   `docs/published-url` branch and integrate it like any quick fix).
6. If the app has sign-in: *"En Supabase, **Authentication → URL Configuration → Site URL**,
   poné `https://<domain>`."*
7. Check it: `curl -s -o /dev/null -w "%{http_code}" https://<domain>` must answer 200. Tell the
   user to open it from their phone. At `aprendiz`, teach `deploy` here.
8. Say once: *"El plan gratis de Vercel es para uso personal. Si la app va a ser de un negocio o
   va a cobrar, hay que pasar al plan Pro."*

**Commit author.** Vercel Hobby only builds commits whose author email belongs to the owner's
GitHub account. `/preparar` configures the noreply GitHub email for that reason. If a deploy is
blocked for this, check `git config user.email` against `<id>+<login>@users.noreply.github.com`.

## After the first time

- Integrating an issue publishes it: the result gate calls the option *"integrar (también
  publica)"*.
- `/publicar` only reports. Read the domain from the README, then the latest production deployment
  of the default branch. Run these with the **Bash tool** (PowerShell breaks the `--jq` quoting):

```bash
gh api "repos/<owner>/<repo>/deployments?environment=Production&per_page=1" \
  --jq 'if length == 0 then "none" else (.[0] | "\(.id) \(.sha)") end'
gh api "repos/<owner>/<repo>/deployments/<id>/statuses" --jq 'if length == 0 then "pending" else .[0].state end'
```

| State | Say |
|---|---|
| `success` and the sha is the head of `main` | *"Tu app está publicada y al día: https://<domain>"* |
| `success` on an older sha | *"Se está publicando lo último; en un par de minutos está."* |
| `in_progress`, `queued`, `pending` | *"Se está publicando ahora."* |
| `failure`, `error` | *"La última publicación falló."* Offer to look at the build: open the Vercel dashboard link from the status `target_url` and ask the user to copy the error, then fix it in a quick fix |
| No deployments | Run the first-time import |

## Environment variables later

A new public variable: the user adds it in **Vercel → Project → Settings → Environment
Variables** and redeploys from **Deployments → ⋯ → Redeploy**. A secret variable never goes into
this stack: it needs server code, which is out of scope for a learner's app; discuss it as a new
epic.
