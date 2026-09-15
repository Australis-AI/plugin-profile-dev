---
description: Arrancar algo nuevo — entendemos qué querés, armamos la épica y, cuando la aprobás, empezamos a construir
argument-hint: "[tu idea]"
---

Load `${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/SKILL.md` and follow its **New work** section,
starting with Step 0 (context) and the preflight.

- The user's idea: $ARGUMENTS
- If there is no idea and `.australis/borrador.md` exists here, resume at the epic gate with that
  draft.
- If there is no idea and no draft, ask in one line: *"¿Qué querés construir?"*

At `aprendiz`, read the teaching material named in the session-start line before the first
message, and name the stage (entender) when you begin.
