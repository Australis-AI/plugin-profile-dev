---
name: judgment-day
description: "Revisión adversarial de un cambio: un revisor ciego en el flujo normal, o dos que se contrastan con /juzgar. Trigger: juzgar, que lo juzguen, revisión doble, revisá esto en serio."
license: Apache-2.0
metadata:
  author: australis-ai
  version: "2.0"
---

# Judgment Day — adversarial review

Someone who did not write the code looks for what is wrong with it. You never review the code
yourself: you launch blind reviewers, then confirm or discard what they report.

Prompts and formats: `${CLAUDE_PLUGIN_ROOT}/skills/judgment-day/references/prompts-and-formats.md`.

## Modes

| Mode | Used by | Reviewers | Fixes |
|---|---|---|---|
| **single** | the orchestrator, on every issue in a one-person repo | `australis-dev:jd-judge-a` | `australis-dev:sdd-apply` in correction mode |
| **dual** | `/juzgar`, opt-in | `australis-dev:jd-judge-a` and `australis-dev:jd-judge-b`, in parallel, blind | `australis-dev:jd-fix-agent` |

Model for all of them: `sonnet`.

## Target and criteria

- Target: `git diff <default>...HEAD` for a branch, `gh pr diff <n>` for a PR, or named files.
- Criteria: the issue's "listo cuando" (from `.australis/trabajo/<N>/issue.md` when it exists),
  `${CLAUDE_PLUGIN_ROOT}/skills/dev-context/SKILL.md`, and the security checks in the prompt.
  Inject the same criteria and paths into every reviewer.

## Single mode

1. Launch the single-reviewer prompt. The reviewer never asks anything and never edits.
2. For each finding, **confirm it yourself** before acting: open the cited code and check the
   claim, or write a test that fails because of it. A finding you cannot confirm is not a fix.
3. Confirmed CRITICAL and real WARNING findings → one correction batch → tests again.
   Re-review once. Stop there.
4. Anything left: into the PR's Risks at `dev`; at `aprendiz` mention it only if it is about
   security.

## Dual mode

1. Launch Judge A and Judge B concurrently with identical prompts. Wait for both.
2. Synthesize:

| Situation | Status |
|---|---|
| Both report the same CRITICAL or real WARNING | Confirmed → fix |
| Only one reports it | Suspect → confirm it yourself; fix only if confirmed |
| They contradict each other | Escalate: tell the user in one line and ask |
| Theoretical warnings and suggestions | Info, no fix |

3. At `aprendiz`, fix confirmed findings without asking. At `dev`, show the confirmed list and ask
   once before fixing.
4. After fixes, re-judge both in parallel. At most 2 fix rounds; if issues remain, ask whether to
   continue.
5. Terminal state is always one of: **Aprobado** or **Escalado — necesita revisión humana**.

## Rules

- Classify a warning as real only if normal intended use can trigger it.
- Missing row-level security, a secret in code, or an unauthenticated write is always CRITICAL.
- Never paste reviewer output to the user; report what was found, fixed, and left, in Spanish.
