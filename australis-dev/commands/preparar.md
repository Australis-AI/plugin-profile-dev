---
description: Terminar la instalación del kit — memoria, PATH y verificación final
---

Read `${CLAUDE_PLUGIN_ROOT}/skills/preparar/SKILL.md` FIRST, then follow it exactly, step by step.

Run this once, right after installing the plugin and restarting Claude Code.

If the argument is `memoria`, run only Steps 2–5 of that runbook (the memory install), not the
whole thing.

CONTEXT:

- Working directory: !`pwd`
- Git: !`git --version 2>/dev/null || echo "FALTA"`
- Memory program: !`engram --version 2>/dev/null || echo "FALTA"`
- Memory declined earlier: !`test -f "$HOME/.claude/australis/memoria-off" && echo "sí" || echo "no"`
- Argument: $ARGUMENTS
