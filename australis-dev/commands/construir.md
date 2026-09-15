---
description: Construir el próximo paso de la épica — rama, código, pruebas, revisión y te muestro que anda
argument-hint: "[#número de issue]"
---

Load `${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/SKILL.md` and follow its **Build an issue**
section, starting with Step 0 (context).

- Issue requested: $ARGUMENTS (empty means the next open issue of the open epic).
- Do not execute phase work inline: explore, design, apply and verify are delegated to their
  sub-agents.
- The run ends at the **"Esto anda"** gate. Stop there and wait for `integrar`, `corregir` or
  `dejar en la rama`.
