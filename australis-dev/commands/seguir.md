---
description: Retomar donde quedaste — lee lo guardado y sigue por la fase que corresponde
---

Load `${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/SKILL.md` and act as the orchestrator.

WORKFLOW:

1. Read `.australis/proyecto.md` if it exists — that is the accumulated truth about this project.
2. List `.australis/cambios/` to find changes in flight.
3. If the `mem_search` tool exists, also search `sdd/{change-name}` for anything the files miss.
4. Work out the next phase from which artifacts exist:

   | Last artifact present | Next phase |
   |---|---|
   | none | `explore` |
   | `explore.md` | `spec` |
   | `spec.md` + `tasks.md` | `design` |
   | `design.md` | `apply` |
   | tasks partly `[x]` | `apply` (continuation — read, merge, write) |
   | all tasks `[x]` | `verify` |

5. Greet with context in one sentence, then one question. Example:
   *"Veníamos con la app de las plantas. Habías dejado pendiente 'avisar por notificación'.
   ¿Vamos con eso?"*
6. On confirmation, run the resolved phase and continue the normal flow with its checkpoints.

If nothing is in flight, say so plainly and ask what they want to build.

CONTEXT:

- Working directory: !`pwd`
- Current project: !`basename "$(pwd)"`
- Current branch: !`git branch --show-current 2>/dev/null || echo "(sin git)"`
- Changes on disk: !`ls -1 .australis/cambios 2>/dev/null || echo "(ninguno)"`
- Filter: $ARGUMENTS
