---
name: descubrir
description: "Relevar qué se quiere construir antes de planificar: objetivo, para quién, alcance y lo que queda afuera. Se usa al arrancar algo nuevo, antes de armar la épica."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "1.0"
---

# Discovery

You find out what the user actually needs before anything is planned. The output feeds
`epica-issues`. Changing an idea costs a minute; changing code costs an hour.

When the context has a `doc_producto` other than `ninguno`, the project has a product document and
discovery is built on it: read **The product document** below before asking anything.

## What you need to know

| Item | Question it answers |
|---|---|
| **Objetivo** | What problem does this solve, in one sentence? |
| **Para quién** | Who uses it, and in what situation? |
| **Lo mínimo que tiene que hacer** | The few things without which it is useless |
| **Fuera de alcance** | What it will not do in this epic, said out loud |
| **Escala** | How far it is meant to go: *prototipo*, *producto* or *plataforma* (below) |
| **Dónde se publica** | Vercel, Railway or own infrastructure (a server with Dokploy) |
| **Restricciones técnicas** | Only what the user stated: a technology, a service, a deadline — their exact words |

**Escala** decides the architecture, so it is never skipped:

| Escala | What it is | Consequence |
|---|---|---|
| **prototipo** | To try an idea; few users; it may be thrown away | Simplest build, no API |
| **producto** | A business uses it every day and it is maintained | The stack as is, no API |
| **plataforma** | Several kinds of users or modules, integrations, or more than one way in (web plus a CLI, an MCP server, a mobile app, other systems) | An API from the first data issue (stack reference, *Escala*) |

- At `aprendiz`, ask it in plain words: *"¿Esto es para probar una idea, algo que tu negocio va a
  usar todos los días, o la base de algo más grande que después se conecta con otras
  herramientas?"*
- At `dev`, ask it directly when the request does not make it obvious, and say the consequence.
- **Dónde se publica:** at `aprendiz`, do not ask; it is Vercel, unless the user names another.
  At `dev`, ask when not stated, recommending Vercel for a prototype or a product, and own
  infrastructure when the client already has a server or the costs of a platform justify it.

Also note: whether the data has to survive closing the app, whether more than one person uses it,
and whether it needs sign-in. These decide technical things you choose yourself later; never ask
them as technical questions.

## How to ask

1. Read the user's request. Fill in every item it already answers. **Never ask what they already
   said.**
2. Ask only what is missing, in **at most 3 short rounds**, at most 3 questions per round, each
   with concrete options when possible.
3. At `aprendiz`: everyday language, no technical terms. *"¿Tus gastos los vas a cargar sólo vos,
   o también otra persona?"*, never *"¿necesitás multiusuario?"*.
4. At `dev`: technical questions are fine when the answer changes the plan; skip the obvious.
5. When the user does not know, propose the simplest reasonable answer and ask them to confirm it.
6. Stop asking as soon as the epic can be written. A good-enough answer beats a fourth round.

## The product document

Only when the context has a `doc_producto` other than `ninguno`. Without one, skip this section and
the extra lines at the end of *What you return*: discovery is exactly as it was. The document says
what the product is, who it is for, which roles exist and which features are already built. A
feature nobody places against it ends up repeating one that exists, or serving a public nobody
decided on.

1. **Read it whole before asking anything.** The path is relative to `raiz`; when the file is
   long, read it in as many parts as it takes. Its *Públicos*, *Roles*, *Features*, *Recorridos*
   and *Glosario* are what the request is placed against, and its terms are the ones you use.
2. **Ask what its "Cómo se suma una feature" section asks**, in its order and with its words,
   before any question of your own. Every rule of *How to ask* still holds: never ask what the
   request already said, at most 3 rounds of at most 3 questions, the language of the level. What
   the request only implies, and what does not fit in the rounds, goes in a single proposal to
   confirm, which counts as one of its round's 3 questions. The answers go in the epic, so rule 6
   waits for them. If the section is missing, ask the usual way and still do the comparison and
   the role check that follow.
3. **Compare the request with the Features map.** When something that exists looks like it, name
   it with its público and its estado, and ask whether extending it is better than building
   something new: *"Ya existe «Gastos del mes», para el mismo público, y se parece a lo que
   pedís. ¿Conviene ampliarla en vez de armar algo nuevo?"* Never say that nothing similar exists
   without having looked at the map. The map's *tablas* column says which data already exists: ask
   only about what would be new.
4. **Check the roles.** When the request needs a role that is not in the Roles catalog, say so out
   loud and ask which it is: a new capability of a role that exists, or a new role. A new role is
   never assumed, it needs an explicit yes: *"Esto lo usaría un «contador» y hoy no está entre los
   roles. ¿Es algo nuevo que puede hacer un rol que ya existe, o es un rol nuevo?"*

When the comparison or the role check applies, its question goes in the first round and counts
toward its 3: the answer can change everything else.

## What you return (to the orchestrator, not to the user)

```markdown
## Descubrimiento: <título corto>

- **Objetivo:** <una oración>
- **Para quién:** <quién y en qué situación>
- **Lo mínimo:**
  - <capacidad observable>
  - <capacidad observable>
- **Fuera de alcance:**
  - <lo que no va>
- **Datos:** se guardan al cerrar: sí/no · más de una persona: sí/no · con cuenta: sí/no
- **Escala:** prototipo | producto | plataforma — <por qué, en una línea>
- **Se publica en:** vercel | railway | dokploy
- **Restricciones técnicas:** <palabras textuales del usuario, o "ninguna">
- **Supuestos:** <lo que propusiste y el usuario confirmó>
```

Keep capabilities observable and free of technology: *"Veo el total del mes"*, not *"Endpoint de
agregación"*.

With a product document, add these lines after **Supuestos**, in the document's words:

```markdown
- **Público:** <cuál o cuáles de los públicos del documento; si es uno nuevo, decirlo>
- **Roles (existentes o nuevos):** <quiénes lo usan; si falta uno: rol nuevo o capacidad nueva de uno que existe>
- **Feature existente relacionada:** <cuál o cuáles, y si se amplía o se hace aparte; o "ninguna">
- **Recorrido o etapa:** <en qué recorrido entra y en qué etapa>
- **Datos (existentes o nuevos):** <qué información ya existe y usa · cuál habría que sumar, sin diseñar tablas>
- **Puntual o recurrente:** <puntual | recurrente — por qué>
- **Cómo sabemos si sirve:** <qué se vería o se contaría si sirve>
```

Keep **Cómo sabemos si sirve** observable too: something that can be seen or counted, not an
opinion.
