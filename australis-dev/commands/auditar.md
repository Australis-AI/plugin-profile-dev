---
description: Auditar el proyecto — qué está mal, qué va a doler cuando crezca y qué conviene hacer de otra forma; lo que elijas se vuelve issues
argument-hint: "[área o tema: una carpeta, seguridad, tests…]"
---

Load `${CLAUDE_PLUGIN_ROOT}/skills/auditar/SKILL.md` and follow it, starting with the context.

- Scope from the user: $ARGUMENTS (empty means the whole repository).
- Nothing is written until the user picks what to do. The auditors run in parallel as
  sub-agents; you confirm each finding before showing it.
- The run ends at *"¿Cuáles hacemos?"*. Stop there and wait.
