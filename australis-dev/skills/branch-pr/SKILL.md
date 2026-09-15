---
name: branch-pr
description: "Ramas, commits y pull requests del método: rama por issue desde la rama por defecto, commits convencionales y PR con contexto, decisiones, riesgos y verificación. Se usa al crear la rama de un issue y al abrir su PR."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "4.0"
---

# Branches, commits and pull requests

The default branch is updated **only by a merged pull request**. Everything here serves that.

## Hard rules

1. Never commit or push to the default branch. The guard hook blocks it; do not try to get around
   it.
2. Never force-push, never rewrite published history.
3. Never add AI attribution, `Co-Authored-By`, or "generated with" lines to commits or PRs in the
   user's repository.
4. `git add` and `git commit` are separate commands.
5. Conventional commits in English. Issues in Spanish; PRs in English.

## The default branch

Take `rama_por_defecto` from the context script. It comes from GitHub first and is never assumed
to be `main`. If the context could not resolve it, resolve it in this order and use the first that
exists:

```bash
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name
git symbolic-ref --short refs/remotes/origin/HEAD   # strip "origin/"
```

`git config init.defaultBranch` alone is not evidence: Git for Windows sets it to `master`
system-wide.

## Branch names

```
^(feat|fix|chore|docs|refactor|test|perf|style|build|ci|revert)/[a-z0-9._-]+$
```

- Issue work: `feat/<N>-<slug>` for new behaviour, `fix/<N>-<slug>` for a bug.
- Quick fixes without an issue: `fix/<slug>` (or `chore/`, `docs/` when that fits better).
- The slug is short, **English**, lowercase, hyphenated, even when the issue is in Spanish:
  issue *"Cargar un gasto"* → `feat/2-add-expense`.
- Always branch from the default branch after `git pull --ff-only`.

## Commits

```
^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9._-]+\))?!?: .+
```

- Imperative, lowercase subject, no trailing period, under ~72 characters.
- One commit per work unit: a behaviour, a fix, a migration, with its tests.
- Body only when the why is not obvious; record accepted costs there when there is no PR yet.

```
feat(expenses): add expense form with amount and description
fix(totals): include today's expenses in the monthly total
test(expenses): cover empty description validation
```

## Pull request

Title: the conventional form of the issue's outcome, e.g. `feat(expenses): add an expense`.

Body (`pr.md`), in English:

```markdown
Closes #<N>

## Context
<why this change exists: the issue's goal in one or two sentences>

## Decisions
| Decision | Chosen | Rejected alternative | Why |
|---|---|---|---|
<from design.md; for a direct route, the one or two choices that matter — or "No design decisions: follows existing patterns">

## Risks
- <accepted costs, unconfirmed review findings, inherited test failures — or "None">

## Verification
<the Verification section of verify.md: criterion table with evidence, test/build/lint results, new vs inherited failures>
```

Rules:
- `Closes #<N>` on its own first line, so merging closes the issue.
- Quick fixes without an issue: no `Closes` line.
- Never paste raw logs; summarize command, exit code, counts.

Commands:

```bash
git push -u origin HEAD
gh pr create --base <default> --title "<title>" --body-file .australis/trabajo/<N>/pr.md
gh pr edit <pr> --body-file .australis/trabajo/<N>/pr.md     # when it already exists
gh pr checks <pr>
gh pr merge <pr> --squash --delete-branch                    # only from the result gate
```

## Team repositories

When the context says `tipo_de_repo: equipo`, request review from the people who reviewed or
authored recent PRs (`gh pr edit <pr> --add-reviewer <login>`) only if the user names them or the
repository has `CODEOWNERS` (GitHub assigns those automatically). Never merge a team PR.
