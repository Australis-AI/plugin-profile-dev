---
name: epica-issues
description: "Redactar la épica, sus milestones y sus issues ordenados en GitHub, con criterios de 'listo cuando' verificables. Se usa después de descubrir, para sumar un issue a una épica abierta, o para definir un cambio chico."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "1.0"
---

# Epic and Issues

The epic is the single source of pending work. Its issues are grouped in **milestones**: stretches
of work that each end with something the user can use. Each issue is one step that can be built,
checked and integrated on its own. All of it is written in **Spanish**, for the person who
approves it.

```
épica (el objetivo, la escala, el alcance)
 ├─ M1 · <lo que se va a poder hacer al cerrarlo>   ← issues 1..n
 ├─ M2 · <…>                                        ← issues
 └─ M3 · <…>
```

## Writing rules

1. **Criteria are observable and free of technology.** If the implementation could change without
   the user noticing, it does not belong in a criterion.
   - ✅ *"Cuando cargo un gasto y cierro la app, al volver sigue ahí."*
   - ❌ *"Se persiste en la tabla expenses de Supabase."*
2. **Form: "Cuando …, entonces …"** whenever the criterion is a behaviour. Plain statements are
   fine for things that just exist (*"La pantalla de inicio muestra el total del mes."*).
3. **Each criterion is checkable by running something**: a test, a request, or looking at the app.
4. **3 to 6 criteria per issue** (1 to 3 for a small change). More than 6 means the issue is two
   issues.
5. **One issue = one step the user can see working.** Order issues so each one builds on the
   previous and leaves the app usable.
6. **Technical constraints** go in their own section, in the user's exact words. They are the one
   place technology is allowed, and they bind design.
7. **No behaviour change** (refactor, dependency update, tooling): write *"Sin cambio de
   comportamiento"* as the only criterion plus what must keep working (*"los tests existentes
   siguen pasando"*).
8. Titles: short, imperative, Spanish. *"Cargar un gasto"*, not *"Implementación del alta"*.

## Milestones

How to split:
1. **A milestone ends with something the user can use or show**, not with a layer of the code.
   ✅ *"M2 · Cargar un gasto y ver el total del mes"*. ❌ *"M2 · Backend"*.
2. **In order:** each one builds on the previous and leaves the app usable. Milestones are built
   one after the other, never two at once.
3. **Size:** 3 to 8 issues. More than 8 means it is two milestones. A *prototipo* usually has
   one; a *plataforma* several.
4. **M1 holds the foundations:** issue #1 *"Base del proyecto"* for a new app, plus the first
   thing that can be used.
5. **Title:** `M<n> · <resultado>`, Spanish, the result in the user's words.

Milestone description (Spanish; GitHub lists its issues and shows its progress, so it does not
repeat them):

```markdown
**Qué es.** <una o dos oraciones: el tramo del producto que se construye>

**Qué se va a poder hacer al terminarlo.**
1. <capacidad, en palabras del usuario>
2. <…>

**Qué implica.** <solo si hay algo que el usuario tiene que saber: datos que se migran, una
primera publicación, un servicio que se suma; si no, omitir>

**Qué queda afuera.** <lo que llega en un milestone posterior, y cuál>

**Está terminado cuando** <un recorrido concreto en la app que lo demuestra>.
```

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

## A small change

A standalone issue: no epic, no discovery. Same body and the same writing rules, with 1 to 3
criteria and the label `cambio-chico`. The definition is short, not optional: it is still what
the result is checked against.

```markdown
**Título:** Botón de guardar en azul

## Qué
El botón principal del formulario se ve en el azul de la marca.

## Listo cuando
- [ ] Cuando abro el formulario, entonces el botón de guardar se ve azul.
```

## Epic body

Title: the product or feature name, no prefix (*"Gastos personales"*). Label: `epica`.

```markdown
## Objetivo
<una oración>

## Para quién
<quién y en qué situación>

## En el producto
<sólo si el descubrimiento trajo estos campos (el proyecto tiene documento de producto); si no, omitir la sección>
- **Público:** <…>
- **Roles (existentes o nuevos):** <…>
- **Feature existente relacionada:** <…>
- **Recorrido o etapa:** <…>
- **Datos (existentes o nuevos):** <…>
- **Puntual o recurrente:** <…>
- **Cómo sabemos si sirve:** <…>

## Escala
<prototipo | producto | plataforma> — <por qué, en una línea>. Se publica en <Vercel | Railway | infraestructura propia>.

## Alcance
- <capacidad>

## Fuera de alcance
- <lo que no va en esta épica>

## Listo cuando
- [ ] <el resultado global que da por terminada la épica>

## Pasos

### M1 · <resultado>
- [ ] #<N> <título del issue>
- [ ] #<N> <título del issue>

### M2 · <resultado>
- [ ] #<N> <título del issue>

---
Aprobada en la sesión del <AAAA-MM-DD>.
```

**En el producto** exists only when the discovery brought the product lines (the project has a
product document). Copy them as they came, in the document's words: the person who approves the
epic is also approving where the feature sits in the product. Without them, omit the section and
the epic is as it always was.

## Creating them (the orchestrator runs this after approval)

Run them with the **Bash tool**.

1. `gh label create epica --color 5319E7 --force`
2. For each milestone, in order: write its description to a temporary file and run
   `gh api repos/<owner>/<repo>/milestones -f title="M<n> · <resultado>" -F description=@<archivo>`.
3. For each issue, in order: write the body to a temporary file and run
   `gh issue create --title "<título>" --milestone "M<n> · <resultado>" --body-file <archivo>`.
   Read the number from the URL it prints.
4. The epic last, with the real numbers in **Pasos**: `gh issue create --title "<título>" --label
   epica --body-file <archivo>`. The epic itself has no milestone: it spans all of them.

GitHub links each `#N` in the epic to its issue, so issues never need editing to point back.

## Adding an issue to an open epic

Create the issue as above, in the milestone it belongs to: the current one if it is needed to
finish it, a later one otherwise. Then add `- [ ] #<N> <título>` under that milestone in the
epic's **Pasos** with `gh issue edit <epic> --body-file <archivo>` (read the current body first
and keep everything else intact). A new stretch of work that does not fit an existing milestone
gets a new milestone at the end, created as above.

## An epic created before milestones

When an open epic has a flat **Pasos** list, leave it as it is until the user plans more work in
it. Then propose grouping the open issues in milestones, show the grouping at the gate, and only
after approval create the milestones, assign the issues (`gh issue edit <N> --milestone "…"`) and
regroup **Pasos**.
