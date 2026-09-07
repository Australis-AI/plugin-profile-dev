---
description: Arrancar un cambio nuevo — explora el proyecto y arma el plan que vas a aprobar
---

Load `${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/SKILL.md` and act as the orchestrator.
Do NOT execute phase work inline — delegate to sub-agents.

WORKFLOW:

1. Check the **Escape Hatch** first. If this is a trivial edit, just do it and stop.
2. Delegate to the `australis-dev:sdd-explore` sub-agent (model: `sonnet`).
3. Present **Checkpoint 1 — "Esto entendí"**: up to 5 plain-Spanish scope bullets plus a
   "Por ahora NO va a…" block. Ask: *"¿Está bien así, o cambio algo?"* Then STOP and wait.
4. Once approved, delegate to the `australis-dev:sdd-spec` sub-agent (model: `opus`).
5. Present **Checkpoint 2 — "Esto va a hacer"**: the numbered list of user-visible behaviours,
   verbatim from the spec artifact, plus one line of scale. Ask: *"¿Arranco? Si querés sacar o
   agregar algo, es ahora."* Then STOP and wait.
6. When they approve, tell them to keep going with `/construir` — or just continue if they say yes.

CONTEXT:

- Working directory: !`pwd`
- Current project: !`basename "$(pwd)"`
- Current branch: !`git branch --show-current 2>/dev/null || echo "(sin git)"`
- Protected branch: !`b=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null); echo "${b#origin/}" | grep . || git config --get init.defaultBranch || echo "main"`
- Change name: $ARGUMENTS

If no change name was given, ask for one in plain Spanish — "¿Cómo le decimos a esto?" — and
derive the slug yourself.
