---
name: adr
description: "Registrar una decisión técnica que va a seguir valiendo (ADR): contexto, decisión, alternativas descartadas y consecuencias. Trigger: documentá esta decisión, dejá registrado por qué elegimos esto, hacé un ADR."
license: MIT
metadata:
  author: australis-ai
  version: "1.0"
---

# Architecture Decision Records

An ADR records a decision that will outlive the issue that made it, so the next person — or the
same person in six months — knows why the system is the way it is, and does not reverse it by
accident.

## When to write one

Write one when a decision:
- adds or replaces a service, database, framework or major dependency;
- defines a data model or a rule other features must follow (e.g. "all data access goes through
  `data.ts`");
- chooses between approaches with lasting trade-offs (cost, security, lock-in);
- deliberately breaks an existing pattern.

Do not write one for choices local to a single feature, naming, or anything the code already makes
obvious. `design.md` lists **ADR candidates**; the orchestrator writes the ADR on the issue branch
before opening the PR.

## Where and how

- Folder: `docs/adr/`. File: `NNNN-short-title.md`, numbered in order (`0001-`, `0002-`…).
- Language: the language of the repository's existing documentation; Spanish when there is none.
- Never edit the substance of an accepted ADR. To change a decision, write a new ADR that
  supersedes it and set the old one's status to *Reemplazada por NNNN*.
- Commit: `docs(adr): record <decision>` on the issue branch, in the same PR as the change.

## Template

```markdown
# NNNN. <Decisión en pocas palabras>

- **Estado:** Aceptada | Reemplazada por NNNN
- **Fecha:** AAAA-MM-DD
- **Issue:** #<N>

## Contexto
<El problema y las fuerzas que empujan la decisión: requisitos, restricciones, riesgos.>

## Decisión
<Lo que se decidió, en una o dos oraciones afirmativas.>

## Alternativas descartadas
- **<alternativa>:** <por qué no>

## Consecuencias
- <lo que se vuelve más fácil>
- <lo que se vuelve más difícil o queda como costo aceptado>
```

## At level aprendiz

When the first ADR of a project is written, explain it in one line: *"Dejé anotada esta decisión
en `docs/adr/` para que dentro de un tiempo se sepa por qué la app está hecha así."*
