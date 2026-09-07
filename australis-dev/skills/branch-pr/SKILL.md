---
name: branch-pr
description: "Manejar ramas y pull requests solo, sin que tengas que saber git y sin tocar nunca main. Trigger: abrir un PR, preparar una rama, arrancar una funcionalidad nueva, subir los cambios."
license: MIT
metadata:
  author: australis-ai
  version: "3.0"
---

# Branches and Pull Requests

You manage branches so the user does not have to. The single most important outcome: **their
default branch never gets written to directly.** Everything else here is in service of that.

This applies to **the user's own repository**. Do not assume any particular labels, issue
templates, CI workflows, or review process exist — most projects have none of that, and demanding
them blocks the user on approvals that will never come.

---

## Hard Rules

1. **Never commit or write code on the repository's default branch.** Branch first, always.
   Resolve which branch that is — see *Which branch is protected* below. It is not always `main`.
2. **Never** force-push, never rewrite published history.
3. **Never** add AI attribution, `Co-Authored-By`, or "generated with" trailers to commits or PRs.
4. **Never** block on a label, an approval, or a CI check that this repository does not define.
5. Conventional commits, always.

---

## Branch Discipline

### Step 1 — Which branch is protected

Do not assume it is called `main`. Resolve the repository's real default branch, in this order:

```bash
git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null   # -> "origin/xxx"; strip "origin/"
git config --get init.defaultBranch                             # the user's configured default
```

If neither answers, treat these names as protected when they exist: `main`, `master`, `develop`,
`trunk`. Teams really do use `develop` or `trunk` as their trunk, and a guard that only knows
`main` silently lets the agent commit straight onto it.

### Step 2 — Move off it

```bash
git rev-parse --abbrev-ref HEAD    # where am I?
```

If the current branch is the protected one:

```bash
git checkout -b feat/<slug>
```

Tell the user in exactly one line, no ceremony, naming the real branch:

> Trabajo en la rama `feat/nombre-del-cambio` para no tocar `develop`.

If they are already on a feature branch, stay on it.

If the folder is not a git repository, offer `git init` once. If they decline, work without git
and do not bring it up again.

### Branch naming

```
^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)/[a-z0-9._-]+$
```

`type/description` — lowercase, hyphens, no accents, no spaces.

| Type | When | Example |
|---|---|---|
| `feat` | New behaviour | `feat/user-login` |
| `fix` | Something was broken | `fix/date-off-by-one` |
| `chore` | Maintenance, deps, config | `chore/update-deps` |
| `docs` | Documentation only | `docs/installation-guide` |
| `refactor` | Restructure, no behaviour change | `refactor/extract-shared-logic` |
| `test` | Tests only | `test/add-signup-coverage` |
| `perf` | Performance | `perf/reduce-startup-time` |
| `style` | Formatting only | `style/format-templates` |
| `build` / `ci` | Build system, pipelines | `ci/add-lint-step` |
| `revert` | Undo a previous change | `revert/broken-migration` |

Derive the slug from the change name the user gave. Strip accents: `regar-plantas`, not
`regar-plántas`.

---

## Conventional Commits

```
^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9._-]+\))?!?: .+
```

Format: `type(scope): description` or `type: description`. The `!` marks a breaking change.

Subject in **English**, imperative, lowercase, no trailing period, under ~72 characters. The
commit message is a technical artifact — it does not follow the Spanish user-facing copy rule.

```
feat(plantas): add watering interval per plant
fix(storage): persist plant list across restarts
docs(readme): document the setup steps
refactor(list): extract due-today filter
chore(deps): update date library
feat!: replace local storage with a database
```

Report back to the user in **plain Spanish**, describing what was saved in their words — never
the commit message itself:

> Guardé dos cosas:
> • La pantalla que lista las plantas
> • El botón de "Regada" y el cálculo de la próxima fecha

---

## Pull Requests — optional, never forced

A PR only makes sense when the repository has a remote on GitHub and `gh` is authenticated.
Check before offering. If either is missing, say nothing about PRs — the work is safely committed
on a branch and that is enough.

When it does apply, ask once:

> ¿Querés que lo suba a GitHub y abra un pull request, o lo dejamos en la rama por ahora?

### PR body

Keep it short and useful. No template file is required.

```markdown
## Qué cambia

- <one to three bullets, plain language>

## Cómo probarlo

<the exact command or the steps>
```

If the repository **does** have issue linkage conventions, and an issue exists for this work, add
`Closes #N`. If no issue exists, **do not create one just to satisfy a convention** — link nothing.

### Optional niceties, only if the repo already uses them

- Labels: add one only if the repository already defines a label taxonomy.
- Reviewers: request one only if the user names someone.
- CI: if checks exist, wait and report the result in plain Spanish. If they fail, say what failed
  and offer to fix it. If no checks exist, do not mention CI.

---

## Commands

```bash
# Branch off the protected branch
git checkout -b feat/my-feature

# Push and open a PR (only when gh is authenticated and a remote exists)
git push -u origin feat/my-feature
gh pr create --title "feat(scope): description" --body-file <file>

# Resolve the protected branch
git symbolic-ref --short refs/remotes/origin/HEAD
git config --get init.defaultBranch

# Check whether PRs are even possible here
git remote -v
gh auth status
```

---

## Splitting large changes

If the diff grows past roughly 400 changed lines, review quality drops sharply. See
`${CLAUDE_PLUGIN_ROOT}/skills/chained-pr/SKILL.md` for how to split it into a reviewable chain,
and `${CLAUDE_PLUGIN_ROOT}/skills/work-unit-commits/SKILL.md` for how to group commits.

Raise this with the user in plain Spanish — *"esto quedó grande, lo parto en dos para que se pueda
revisar bien"* — and then just do it. Do not present a strategy menu.
