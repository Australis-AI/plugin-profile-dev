---
name: orchestrator
description: "Conduce el método de desarrollo de Australis: épica e issues en GitHub, una rama por issue, pull request, revisión, integrar y publicar. Trigger: quiero hacer una app, agregá esta funcionalidad, arreglá, cambiá, construí, seguí con lo que veníamos, hacé el issue."
license: MIT
metadata:
  author: australis-ai
  version: "3.0"
---

# Australis — Orchestrator

You run the method. You talk to the user, decide the route, delegate phase work to sub-agents,
and you alone perform actions with effects outside the working copy. How you talk (depth,
teaching, non-negotiables) comes from the output style; this skill is the procedure.

## The method

```
entender ─▶ acordar ─▶ construir ─▶ probar ─▶ integrar ─▶ publicar
 descubrir   épica      rama +      gate de    merge       deploy
             aprobada   fases + PR  resultado  por PR      desde main
```

- **GitHub is the source of truth.** The epic and its issues hold the WHAT (Spanish, approved by
  the user). The PR holds the HOW and the evidence (English). The repository keeps only permanent
  documentation (README, ADRs, runbooks).
- **Two approvals only:** the epic, once; and the result of each issue, before it is integrated.
  Stop before building only when an issue changes scope or needs a decision from the user.
- **Local working files are ephemeral:** `.australis/trabajo/<N>/` per issue, ignored by git
  through `.australis/.gitignore` containing `*`. Create both when missing. Never commit them.
- **Stage names** (say them at `aprendiz`, see the teaching material): entender, acordar,
  construir, probar, integrar, publicar.

## Step 0 — Context, always first

Run the context script with the **Bash tool** (if only PowerShell is available:
`& "$env:ProgramFiles\Git\bin\bash.exe" "<script>"`):

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/contexto.sh"
```

It prints `key: value` lines: `nivel`, `onedrive`, `repo`, `firma_git`, `remoto`, `github`,
`repo_github`, `rama_por_defecto`, `rama_actual`, `commits_en_rama_por_defecto`,
`commits_totales`, `cambios_sin_commitear`, `tipo_de_repo`, `epica_abierta`, `pr_de_la_rama`,
`comando_test`, `comando_dev`, `comando_build`, `comando_lint`, `gestor_paquetes`, `stack`,
`app_publicada`.
Read it silently. Re-run it after any step that changes branches or GitHub state.

Stop and send the user to `/preparar` (one line) when a write is needed and `github` is
`sin conectar` or `firma_git` is `falta`.

## Route the request

| The user asks for | Route |
|---|---|
| A question, an explanation, running tests, reading code | Answer directly. No branch, nothing written. |
| A small change: copy, a color, a typo, one obvious fix | **Quick fix** |
| Something new: an app, a feature, several steps | **New work** (`/nuevo`) |
| "hacé el #4", "construí lo que sigue", "seguí con la épica" | **Build an issue** (`/construir`) |
| "seguí", "¿dónde quedamos?", a new session mid-issue | **Resume** (`/seguir`) |
| "publicala", "subila a internet", "¿está publicada?" | **Publish** (`/publicar`) |

Grey zone: start as a quick fix. If it grows past about three files, or needs a decision from the
user, stop and turn it into an issue of the open epic (*"Esto es más grande de lo que parecía: lo
sumo como un paso de la épica y lo hacemos ordenado."*).

## Actions with effects happen here, never in a sub-agent

Only the main thread runs: `gh repo create`, `git push`, `gh label`/`gh issue`/`gh pr` writes,
`gh pr merge`, database migrations, deploys. Phase agents write code, run tests and commit
locally on the issue branch.

- Run `git add` and `git commit` as **separate** commands: the guard hook blocks them combined,
  because it inspects what is staged before the commit.
- Run `gh … --jq '…'` from the **Bash tool**: PowerShell splits the jq expression and gh fails.
- If Claude Code denies an action, do not look for another way to do it. Give the user one
  sentence to type that names the action and its target, e.g. *"Integrá el PR #4 de gastos a
  main"*, and retry after they send it.
- The guard hook blocks commits and pushes on the default branch and commits with secrets. When
  it blocks, relay its message in one line and fix the cause; never try to get around it.

---

## New work — `/nuevo <idea>`

### 1. Preflight (silent)

Classify the folder from the context:

| Case | Condition | What you do |
|---|---|---|
| **A. Existing repo** | `repo: si`, a GitHub remote, `commits_en_rama_por_defecto` > 1 | Work here. At `aprendiz`, if an epic is open and the idea looks unrelated, ask once: *"¿Esto es parte de «<épica>» o es otra app?"* |
| **B. Fresh repo** | `repo: si`, a GitHub remote, 1 commit (README from GitHub) | Work here. This is a new app. |
| **C. No repo yet** | `repo: no`, or `onedrive: si` at `aprendiz`, or "otra app" in case A | Run discovery here first, then create the project (below). |
| **D. Loose code** | `repo: no` with files, or a repo without a GitHub remote | Run discovery, create the project (below), and make issue #1 *"Traer lo que ya estaba"*: copy the existing files (never `node_modules`, `.next`, `dist`, `.env*`) into branch `feat/1-import-existing-code` of the new clone. |

**Creating the project (C and D).** The repository is born on GitHub and cloned, so `main`
exists before any commit of yours and the remote is configured by the clone:

```
gh repo create <owner>/<slug> --private --add-readme --gitignore Node --clone
```

(`--gitignore Node` for a web app; at `dev`, pick the template for the stack or omit it.)

- `<owner>`: at `aprendiz`, the gh login. At `dev`, if `gh api user/orgs --jq '.[].login'` returns
  organizations, ask which owner in the same message as the epic gate.
- Where: at `aprendiz`, inside `%USERPROFILE%\apps` (create it). At `dev`, the parent of the
  current folder when the current folder is empty and named like the slug; otherwise ask where.
- Save the approved discovery to `.australis/borrador.md` inside the new clone, then say:
  *"Creé tu proyecto. Abrí la carpeta `%USERPROFILE%\apps\<slug>` (Archivo → Abrir carpeta → Sí,
  confío) y escribí `/nuevo`: sigo desde donde quedamos."* A `/nuevo` without arguments in a
  folder with `.australis/borrador.md` resumes at the epic gate.

### 2. Discover

Load `${CLAUDE_PLUGIN_ROOT}/skills/descubrir/SKILL.md` and follow it. It returns the goal, who it
is for, scope, out of scope, and any technical constraints the user stated in their own words.

### 3. Draft the epic and issues

Load `${CLAUDE_PLUGIN_ROOT}/skills/epica-issues/SKILL.md` and draft the epic and its ordered
issues. For a new app (case B or C), issue #1 is always *"Base del proyecto"*.

### 4. Gate — the user approves the epic

Show the epic as the user will read it: goal, scope, out of scope, and the numbered list of issues
with their "listo cuando" criteria. At `dev`, add the technical approach and main risks in up to
three lines. Close with: *"¿La aprobás así, o cambiamos algo?"* Then **stop and wait**.

- Changes requested: apply them to the draft and show the gate again.
- Approved: write to GitHub, in this order —
  1. `gh label create epica --color 5319E7 --force`
  2. each issue in order with `gh issue create --title … --body-file …`, reading the number from
     the returned URL;
  3. the epic last, with label `epica`, its task list `- [ ] #N` pointing at the real numbers, and
     the line *"Aprobada en la sesión del <fecha>."*
- Tell the user the epic number and the first issue in one line, then continue straight into
  **Build an issue** with the first one. No extra approval is needed to start building.

---

## Build an issue — `/construir [#N]`

### 1. Pick the issue

The number given, or the first open issue in the task list of the open epic (`gh issue view
<epic> --json body`). No open epic: at `aprendiz` suggest `/nuevo`; at `dev` list open issues
(`gh issue list`). More than one open epic: ask which. At `dev`, building an issue outside the
epic adds it to the epic's task list.

### 2. Branch

1. If `cambios_sin_commitear` > 0 and the current branch is not this issue's branch, ask once:
   *"Hay cambios sin guardar. a) Los llevo a este paso b) Los guardo aparte c) Cancelo"*.
   b) is `git stash push -u -m "australis <fecha>"`.
2. `git checkout <rama_por_defecto>` and `git pull --ff-only`.
3. Branch name: `feat/<N>-<slug>` for new behaviour, `fix/<N>-<slug>` for a bug. The slug is
   short, English, lowercase, hyphenated. If the branch already exists, check it out instead.
4. `git checkout -b <branch>`. At `aprendiz`, teach `rama` the first time.

### 3. Working files

- Ensure `.australis/.gitignore` contains `*`.
- `.australis/trabajo/<N>/issue.md`: `gh issue view <N> --json number,title,body,comments` written
  as markdown.
- `.australis/trabajo/<N>/contexto.md`: the context script output.
- **Baseline:** when `comando_test` is not `ninguno` and `baseline.md` does not exist, run the test
  command once on the fresh branch (timeout 600000) and record which tests fail, or *"sin fallas"*.
  Failures that exist here are inherited; only new ones block integration.

### 4. Route the issue

**Base of a new app.** When the issue is *"Base del proyecto"* and there is no `package.json`,
follow the **Issue #1** section of `${CLAUDE_PLUGIN_ROOT}/skills/stack-australis/SKILL.md` in this
thread instead of routing to explore, design and apply. Verify, review, PR and the gate run as
usual.

**Saved data.** When an issue needs data that survives closing the app and `.env.local` has no
`NEXT_PUBLIC_SUPABASE_URL`, connect Supabase first with
`${CLAUDE_PLUGIN_ROOT}/skills/stack-australis/references/supabase.md`. Migrations written by apply
are applied and live-checked **before** verify.

Otherwise, judge the route now, not when the issue was written:

| Route | When |
|---|---|
| **Direct** — apply → verify | Known bug, small well-understood change, the criteria fully describe the result, no open design question |
| **Explore first** — explore → design (only if needed) → apply → verify | Architecture decisions, several viable approaches, unclear scope, unfamiliar code, or the user flagged doubts |

If genuinely ambiguous: at `dev`, one question (*"a) Voy directo b) Exploro primero"*); at
`aprendiz`, explore and say so in one line.

If exploring shows the issue changes the epic's scope or needs a decision only the user can
make, stop and ask before building. That is the only stop before the result.

### 5. Phases

Delegate with the model table below. Every launch passes: the issue number, the absolute path of
`.australis/trabajo/<N>/`, the default branch, and under `## Skills to load before work` the
exact paths `${CLAUDE_PLUGIN_ROOT}/skills/dev-context/SKILL.md` and
`${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md`, plus
`${CLAUDE_PLUGIN_ROOT}/skills/stack-australis/SKILL.md` when the context says `stack: australis`.
When `comando_test` is not `ninguno`, add `STRICT TDD MODE IS ACTIVE. Test runner: <comando_test>.`

- **explore** → `explore.md`, including whether design is needed.
- **design** (when needed) → `design.md`. At `dev`, show its Decisions table (chosen and rejected,
  up to 8 lines) before apply and continue without waiting.
- **apply** → code, commits on the branch, `apply-progress.md`. After each apply return, push:
  `git push -u origin HEAD`. Show one progress line per criterion completed.
- **verify** → `verify.md`: per criterion ✅/❌ with executed evidence, new failures vs baseline.

If verify fails: launch apply in **correction mode** with `verify.md` as input, then verify once
more. If it still fails, go to the gate and show the ❌ with its options.

### 6. Review

By `tipo_de_repo`, never by level:

- **una-persona:** one blind reviewer, `australis-dev:jd-judge-a`, in single-reviewer mode (prompt
  in `${CLAUDE_PLUGIN_ROOT}/skills/judgment-day/references/prompts-and-formats.md`), over
  `git diff <default>...HEAD` against the issue criteria and dev-context. It never asks the user
  anything.
  1. For each finding, confirm it yourself: open the cited code, or write a failing test.
  2. Confirmed findings → one apply correction batch → verify again → push.
  3. Unconfirmed findings go to the PR's Risks at `dev`; at `aprendiz` mention them only when they
     are about security.
- **equipo:** no automatic review. The PR asks for human review and you never merge it.

### 7. Pull request

Before the PR, keep permanent documentation current, on the same branch:
- **ADRs:** for each entry under *ADR candidates* in `design.md`, write one with
  `${CLAUDE_PLUGIN_ROOT}/skills/adr/SKILL.md`.
- **README and runbook:** if the change adds or renames an environment variable, changes how to
  run, test or publish, or adds an external service, update them with
  `${CLAUDE_PLUGIN_ROOT}/skills/readme-runbook/SKILL.md`.

Commit those (`docs(...)`) and push. Then build `.australis/trabajo/<N>/pr.md` with `${CLAUDE_PLUGIN_ROOT}/skills/branch-pr/SKILL.md`
(Context, Decisions, Risks, Verification, `Closes #N`) and run `gh pr create --base <default>
--title "<conventional title>" --body-file <pr.md>`, or `gh pr edit --body-file` if it exists.

### 8. Gate — "Esto anda" (probar)

Show, in Spanish:
1. The issue's "listo cuando" criteria, verbatim, each with ✅ or ❌ and one line of evidence in
   plain words.
2. The app running, when `comando_dev` exists: start it in the background (for the australis
   stack, append `-- --hostname 127.0.0.1`), read the URL from its output, and give the link. Stop
   the server when the gate closes and before any package install.
3. The options, answered by writing in the chat:
   - `integrar` — not offered in a team repo. When `app_publicada` is not `no`, call it
     *"integrar (también publica)"*.
   - `corregir` — a correction batch on the same branch, then back to this gate.
   - `dejar en la rama`.

In a team repo, instead of `integrar`: *"Queda esperando la revisión de tu equipo en el PR."*

**Integrating:**
1. If `gh pr checks <pr>` shows failures that are not in the baseline, do not merge; offer
   `corregir`.
2. `gh pr merge <pr> --squash --delete-branch`, then `git checkout <default>` and `git pull
   --ff-only`, then delete `.australis/trabajo/<N>/`.
3. If it was the last open issue of the epic, close the epic with a one-line comment.
4. Offer the next issue in one line: *"¿Seguimos con el #M: <título>?"*

**Integrating with an unmet criterion** (the user wants it anyway): create issue #M in the epic
with that criterion, mark its test `it.todo('<criterio> (#M)')` (or the runner's skip
equivalent), commit, push, note it in the PR's Risks, then integrate with the suite green.

---

## Quick fix

1. Always from the default branch updated: if on an issue branch with changes, commit and push
   those first. Then `git checkout <default>`, `git pull --ff-only`, `git checkout -b fix/<slug>`.
2. Make the change. Collect evidence: a test when the behaviour is testable, otherwise the
   command, output or screenshot you actually ran.
3. Commit, push, the same single reviewer (skip in a team repo), open the PR with `branch-pr`.
4. Show the result and ask to integrate. At `dev`, "…y mergealo" in the same request counts as
   the confirmation; checks, tests and the guard still apply.

"Guardá esto" means commit and push on the current issue branch, or a quick fix when on the
default branch. Something small the user postpones becomes one line in the open epic's body, not
a file.

## Resume — `/seguir`

1. Context. If on an issue branch (`feat/<N>-…` or `fix/<N>-…`):

   | State | Next step |
   |---|---|
   | No `.australis/trabajo/<N>/` (other machine) | Rebuild `issue.md` and `contexto.md`; if the branch has commits, run verify |
   | No `explore.md`/`apply-progress.md` | Route the issue |
   | `apply-progress.md` with pending tasks | Apply continuation |
   | No `verify.md`, or code changed after it | Verify |
   | Verified, no PR | Review and PR |
   | PR open, `CHANGES_REQUESTED` | Read `gh pr view --comments`, correction batch |
   | PR open | Result gate |

2. Otherwise, with an open epic: say which issues are done and propose the next one. Without an
   epic: suggest `/nuevo`.
3. Greet with context in one sentence and one question, e.g. *"Veníamos con «Gastos»: está
   hecho el #1 y sigue el #2, cargar un gasto. ¿Vamos?"*

## Publish — `/publicar`

Production always comes from the default branch, trunk-based: nothing is deployed from a feature
branch, and staging (where it exists) follows the default branch too, so production receives the
same commit that was already seen in staging.

1. Context. If `cambios_sin_commitear` > 0 or the current branch has unintegrated work, say it in
   one line and offer to finish that issue first.
2. Route by owner of `repo_github`:
   - **`Australis-AI/…` (Australis infrastructure):** read the deploy SOP from
     `$CEREBRO_DIR/australis/dev/reference/deploy-dokploy.md` (`CEREBRO_DIR` is an environment
     variable on Agus's machines). If the variable or the file is missing, say *"Este repo se
     publica con el procedimiento interno de Australis, que no está en esta compu."* and stop.
     Otherwise follow the SOP with these method rules on top: PRs always target the default
     branch; the staging app tracks the default branch; production is promoted with the same
     commit; production migrations are manual with a backup. Where the SOP still describes a
     `staging` branch, follow the trunk rules and tell Agus the SOP needs updating. Never copy
     server addresses, hosts or keys from the SOP into the repository, an issue or a PR.
   - **Anything else (clients, Australis stack):** follow
     `${CLAUDE_PLUGIN_ROOT}/skills/deploy-vercel-supabase/SKILL.md`.

---

## Model assignments

Pass `model` in every Agent call.

| Phase | Agent | Model |
|---|---|---|
| explore | `australis-dev:sdd-explore` | sonnet |
| design | `australis-dev:sdd-design` | opus |
| apply | `australis-dev:sdd-apply` | sonnet |
| verify | `australis-dev:sdd-verify` | sonnet |
| review | `australis-dev:jd-judge-a` | sonnet |
| other | — | sonnet |

If a namespaced name does not resolve, list the agent types and use the one whose suffix
matches. Never run a phase inline instead. Every phase returns `status`, `executive_summary`,
`artifacts`, `next_recommended`, `risks`.

## Talking to the user

- Never paste a diff, a stack trace or a file tree. Mention files, do not show them.
- At most 3 questions per message, each with concrete options.
- Failures are choices in the user's words, never a raw diagnosis at `aprendiz`:

```
No salió esto: "el gasto queda guardado al cerrar".
  a) Lo intento de otra forma
  b) Lo paso a un paso nuevo de la épica y seguimos
  c) Contame cómo lo esperabas
```

- Issues in Spanish; branches, commits and PRs in English.
