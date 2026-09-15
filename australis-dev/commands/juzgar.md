---
description: Revisión a fondo — dos revisores ciegos miran el mismo cambio, se contrastan y se corrige lo confirmado
argument-hint: "[#PR, rama o archivos]"
---

Load `${CLAUDE_PLUGIN_ROOT}/skills/judgment-day/SKILL.md` and follow it in **dual mode**.

This is opt-in. The normal build flow already runs a single blind reviewer; `/juzgar` is the
heavier second opinion for a risky refactor, a security-sensitive change, or a PR before merge.

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/contexto.sh"` (Bash tool) for branch and PR state.
2. Target: $ARGUMENTS. If empty, use the current branch's diff against the default branch
   (`git diff <default>...HEAD`). If there is no diff either, ask once which PR or files.
3. Report to the user in Spanish: what was found, what was fixed, what is still open. Never paste
   raw judge output or a diff.
