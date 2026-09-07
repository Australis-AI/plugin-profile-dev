---
description: Revisión adversarial — dos jueces ciegos revisan el mismo código y se contrastan
---

Load `${CLAUDE_PLUGIN_ROOT}/skills/judgment-day/SKILL.md` and follow it exactly.

This is **opt-in only**. Never trigger it automatically as part of the normal build flow — it is
heavier than the standard `verify` phase and is meant for code that warrants a second opinion:
a risky refactor, a security-sensitive change, an architectural slice, or a PR before merge.

WORKFLOW:

1. Establish the target: files, a feature, a PR, or an architecture slice. If unclear, ask once.
2. Launch `australis-dev:jd-judge-a` and `australis-dev:jd-judge-b` **in parallel, blind** — neither sees the other's findings.
   Both get identical prompts and identical skill paths. Model: `sonnet`.
3. Contrast the two verdicts. Only findings both judges raise, or that survive scrutiny, count as
   confirmed.
4. Launch `australis-dev:jd-fix-agent` (model: `sonnet`) with the confirmed findings only.
5. Re-judge the fixes.
6. Report to the user in plain Spanish: what was found, what was fixed, what is still open.
   Never paste raw judge output or a diff.

CONTEXT:

- Working directory: !`pwd`
- Current project: !`basename "$(pwd)"`
- Current branch: !`git branch --show-current 2>/dev/null || echo "(sin git)"`
- Protected branch: !`b=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null); echo "${b#origin/}" | grep . || git config --get init.defaultBranch || echo "main"`
- Changed files: !`git diff --stat HEAD 2>/dev/null | tail -5 || echo "(sin cambios)"`
- Target: $ARGUMENTS
