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

## What you need to know

| Item | Question it answers |
|---|---|
| **Objetivo** | What problem does this solve, in one sentence? |
| **Para quién** | Who uses it, and in what situation? |
| **Lo mínimo que tiene que hacer** | The few things without which it is useless |
| **Fuera de alcance** | What it will not do in this epic, said out loud |
| **Restricciones técnicas** | Only what the user stated: a technology, a service, a deadline — their exact words |

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
- **Restricciones técnicas:** <palabras textuales del usuario, o "ninguna">
- **Supuestos:** <lo que propusiste y el usuario confirmó>
```

Keep capabilities observable and free of technology: *"Veo el total del mes"*, not *"Endpoint de
agregación"*.
