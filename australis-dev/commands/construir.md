---
description: Construir lo que ya acordamos — diseña, escribe el código y verifica que ande
---

Load `${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/SKILL.md` and act as the orchestrator.
Do NOT execute phase work inline — delegate to sub-agents.

Precondition: a spec artifact must exist at `.australis/cambios/<slug>/spec.md`. If it does not,
tell the user *"Todavía no acordamos qué construir"* and run `/nuevo` instead.

WORKFLOW:

1. **Branch discipline first.** Resolve the repository's protected branch per the orchestrator
   skill — it is not always `main`. If the current branch is that one, create and switch to
   `feat/<slug>` and say it in one line.
2. Delegate to the `australis-dev:sdd-design` sub-agent (model: `opus`). Do not show the user a checkpoint —
   design is internal.
3. Delegate to the `australis-dev:sdd-apply` sub-agent (model: `sonnet`). If tasks are already partly marked
   `[x]`, instruct it to read, merge and write — never overwrite.
   Show one progress line per behaviour as it completes.
4. Delegate to the `australis-dev:sdd-verify` sub-agent (model: `sonnet`). This one is non-negotiable: it judges
   code it did not write.
5. Present **Checkpoint 3 — "Esto anda"**: the same numbered list the user approved, same wording
   and order, with ✅/❌ per item. Then the exact command to try it. Close with *"¿Qué sigue?"* and
   at most 3 options.

If verify reports a failure, fix it and re-verify before showing checkpoint 3 — but only once.
If it fails again, show the list with the ❌ and offer the choice in the user's own words.

CONTEXT:

- Working directory: !`pwd`
- Current project: !`basename "$(pwd)"`
- Current branch: !`git branch --show-current 2>/dev/null || echo "(sin git)"`
- Protected branch: !`b=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null); echo "${b#origin/}" | grep . || git config --get init.defaultBranch || echo "main"`
- Change: $ARGUMENTS

If no change was named and there is exactly one folder under `.australis/cambios/`, use it.
If there are several, ask which one in plain Spanish.
