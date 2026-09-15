---
name: epica-issues
description: "Redactar la épica y sus issues ordenados en GitHub, con criterios de 'listo cuando' verificables. Se usa después de descubrir, o para sumar un issue a una épica abierta."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "1.0"
---

# Epic and Issues

The epic is the single source of pending work. Each issue is one step that can be built, checked
and integrated on its own. Both are written in **Spanish**, for the person who approves them.

## Writing rules

1. **Criteria are observable and free of technology.** If the implementation could change without
   the user noticing, it does not belong in a criterion.
   - ✅ *"Cuando cargo un gasto y cierro la app, al volver sigue ahí."*
   - ❌ *"Se persiste en la tabla expenses de Supabase."*
2. **Form: "Cuando …, entonces …"** whenever the criterion is a behaviour. Plain statements are
   fine for things that just exist (*"La pantalla de inicio muestra el total del mes."*).
3. **Each criterion is checkable by running something**: a test, a request, or looking at the app.
4. **3 to 6 criteria per issue.** More than 6 means the issue is two issues.
5. **One issue = one step the user can see working.** Order issues so each one builds on the
   previous and leaves the app usable.
6. **Technical constraints** go in their own section, in the user's exact words. They are the one
   place technology is allowed, and they bind design.
7. **No behaviour change** (refactor, dependency update, tooling): write *"Sin cambio de
   comportamiento"* as the only criterion plus what must keep working (*"los tests existentes
   siguen pasando"*).
8. Titles: short, imperative, Spanish. *"Cargar un gasto"*, not *"Implementación del alta"*.

## New app: issue #1

For a new application the first issue is always:

```markdown
**Título:** Base del proyecto

## Qué
Dejar la app creada, corriendo y lista para construir encima.

## Listo cuando
- [ ] Cuando abro la app en el navegador, entonces veo la pantalla de inicio.
- [ ] Cuando se corren las pruebas, entonces pasan.
```

## Issue body

```markdown
## Qué
<una o dos líneas: qué va a poder hacer o ver la persona>

## Listo cuando
- [ ] Cuando …, entonces …
- [ ] Cuando …, entonces …

## Restricciones técnicas
<sólo si el usuario las dijo, textuales; si no, omitir la sección>
```

## Epic body

Title: the product or feature name, no prefix (*"Gastos personales"*). Label: `epica`.

```markdown
## Objetivo
<una oración>

## Para quién
<quién y en qué situación>

## Alcance
- <capacidad>

## Fuera de alcance
- <lo que no va en esta épica>

## Listo cuando
- [ ] <el resultado global que da por terminada la épica>

## Pasos
- [ ] #<N> <título del issue>
- [ ] #<N> <título del issue>

---
Aprobada en la sesión del <AAAA-MM-DD>.
```

## Creating them (the orchestrator runs this after approval)

1. `gh label create epica --color 5319E7 --force`
2. For each issue, in order: write the body to a temporary file and run
   `gh issue create --title "<título>" --body-file <archivo>`. Read the number from the URL it
   prints.
3. The epic last, with the real numbers in **Pasos**: `gh issue create --title "<título>" --label
   epica --body-file <archivo>`.

GitHub links each `#N` in the epic to its issue, so issues never need editing to point back.

## Adding an issue to an open epic

Create the issue as above, then append `- [ ] #<N> <título>` to the epic's **Pasos** with
`gh issue edit <epic> --body-file <archivo>` (read the current body first and keep everything
else intact).
