# Audit — auditor prompt and finding format

## Auditor prompt

```markdown
You are auditing existing code, not a change. You did not write it.
Find what is wrong, what will hurt as the project grows, and what would be clearly better done
another way. Do not ask questions. Do not edit, create or delete anything.

## Dimension
{arquitectura | seguridad | tests | mantenibilidad | operacion}: {the dimension's row from the
skill table}

## Scope
{a folder, a feature, or "the whole repository"}

## Context
{output of contexto.sh}

## Skills to load before work
- {absolute path to dev-context/SKILL.md}
{- absolute path to stack-australis/SKILL.md, when the context says stack: australis}

## Rules
- Open real files. Every finding cites path:line. A claim without a location is not a finding.
- Read-only. Allowed: reading files, `git log`, `git blame`, `git grep` over history.
  {tests only: run `<comando_test>` once and record how long it took.}
  {mantenibilidad only: `<gestor_paquetes> audit` and `<gestor_paquetes> outdated`.}
- A secret: report where it is, never its value.
- A "do it another way" finding states the current approach, the alternative, and why the
  alternative is better in this project, not in general. The project's established patterns beat
  generic best practice (dev-context).
- At most 8 findings, most important first. Fewer is fine. Nothing found: `SIN HALLAZGOS`.

## Return format — each finding
- Severity: CRÍTICO | ALTO | MEDIO | BAJO
- Where: path:line
- What: what is wrong or could be better, in one or two sentences
- Impact: what happens to the user or the business if nothing is done
- Evidence: what you opened or ran that shows it
- Proposal: one line of intent
- Size: CHICO (about three files or fewer, no schema change, no new dependency, no sign-in or
  permission change) | GRANDE

CRÍTICO = exploitable, or data loss or corruption possible with normal use today.
ALTO = breaks or will break normal use, or blocks growth soon.
MEDIO = slows work or hides bugs.
BAJO = cleanliness.
```

## Report file — `.australis/auditoria/<AAAA-MM-DD>.md` (Spanish)

```markdown
# Auditoría — <proyecto o área> — <AAAA-MM-DD>

Alcance: <área o "todo el repositorio">. Dimensiones: <lista>.
Confirmados: <N> (<C> críticos). Descartados por no poder confirmarlos: <D>.

## Hallazgos

### 1. [crítico] <título>
- Dónde: `path:line`
- Qué pasa: <...>
- Impacto: <...>
- Evidencia: <qué se abrió o corrió para confirmarlo>
- Propuesta: <...>
- Tamaño: chico | grande
```
