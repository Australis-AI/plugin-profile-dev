---
name: readme-runbook
description: "Mantener al día el README y el runbook del proyecto: qué es, cómo se corre, cómo se prueba, qué variables necesita y cómo se publica. Trigger: actualizá el README, documentá cómo se corre, armá el runbook."
license: MIT
metadata:
  author: australis-ai
  version: "1.0"
---

# README and runbook

The README tells a newcomer what this is and how to run it in five minutes. The runbook tells
whoever operates it what to do when something needs doing or breaks. Both describe the system as it
is today — history lives in GitHub.

## When to update

The orchestrator checks this before opening each PR. Update in the same PR when the change:
- adds, renames or removes an environment variable;
- changes how to install, run, test, build or publish;
- adds an external service (a database, an email provider, an API);
- changes what the app does in a way the "Qué es" section no longer describes.

Otherwise, leave the docs alone. Commit: `docs(readme): <what changed>`.

## README shape

Language: the language of the existing docs; Spanish when there is none. Keep the kit's machine
lines exactly as they are (`Stack: australis (…)`, `App publicada: …`).

```markdown
# <Nombre de la app>

<Una o dos oraciones: qué es y para quién.>

App publicada: <url>

## Qué hace
- <capacidad que la persona ve>

## Cómo correrla en tu compu
1. `npm install`
2. Copiá `.env.example` a `.env.local` y completá los valores (ver *Variables*).
3. `npm run dev` y abrí la dirección que aparece.

## Pruebas
- `npm test` — todas las pruebas
- `npm run lint` — revisión de estilo

## Variables
| Variable | Para qué | Dónde se consigue |
|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Dirección de la base de datos | Supabase → Project Settings → API Keys |

## Publicar
<Cómo se publica: "cada integración a main se publica sola en Vercel".>

Stack: australis (Next.js + Supabase + Vitest)
```

Never put a real secret, a password or a private URL in the README.

## Runbook — `docs/runbook.md`

Create it when the app is published for the first time or gets its first external service. One
section per operation, each written as steps someone can follow without knowing the code:

```markdown
# Runbook: <app>

## Publicar una versión
<pasos>

## La app no carga
1. <qué mirar primero> …

## La base de datos se pausó
<pasos para restaurarla>

## Aplicar una migración
<pasos, con backup cuando es producción>

## Rotar una clave
<dónde se genera, dónde se reemplaza, cómo se verifica>
```

Add a section when an issue introduces a new operation; keep each one current when the procedure
changes.
