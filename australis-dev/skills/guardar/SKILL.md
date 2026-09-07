---
name: guardar
description: "Guardar tu trabajo en git con commits ordenados, sin que tengas que saber git. Trigger: guardá esto, guardá el trabajo, hacé un commit, subí los cambios, no quiero perder esto."
license: MIT
metadata:
  author: australis-ai
  version: "1.0"
---

# Guardar — commits for people who do not know git

The user says "guardá esto". They should not have to learn git to keep their work safe.
You handle the mechanics; they see one line of confirmation.

## Hard Rules

1. **Never commit to the repository's default branch.** If that is the current branch, create
   `feat/<slug>` first and say so in one line. Resolve which branch is protected per
   `${CLAUDE_PLUGIN_ROOT}/skills/branch-pr/SKILL.md` — it is not always `main`.
2. **Conventional commits, always.** The subject line is in English and follows the format below —
   it is a technical artifact, not user-facing copy.
3. **Never** use `git add -A` blindly. Stage what belongs to this unit of work.
4. **Never** commit secrets. If a staged file matches `.env*`, `*.pem`, `*.key`, `credentials`,
   or `secrets/`, stop and tell the user in plain Spanish that you are leaving it out.
5. **Never** force-push. Never rewrite published history.
6. If the folder is not a git repo, offer `git init` once. If declined, say nothing more about it.

## Commit format

```
<type>(<scope>): <subject>

<body — only when the subject is not enough>
```

Types: `feat`, `fix`, `chore`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `revert`.

Subject: imperative, lowercase, no trailing period, under ~72 characters. English.

**Never add AI attribution, `Co-Authored-By`, or a "generated with" trailer.**

## Branch naming

```
^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)/[a-z0-9._-]+$
```

Derive the slug from the change name: lowercase, hyphens, no accents.

## What counts as one commit

One reviewable unit of work — a behaviour, plus the tests and docs that belong to it. Not "all my
changes since Tuesday", and not one commit per file.

If the working tree holds several unrelated things, split them into separate commits rather than
one mixed commit. See `${CLAUDE_PLUGIN_ROOT}/skills/work-unit-commits/SKILL.md` for the full
splitting rules.

## Flow

1. Check the branch. Move off the protected branch if needed.
2. `git status --short` and `git diff --stat` to see what is there.
3. Group the changes into units of work.
4. For each unit: stage its files, write the conventional commit, commit.
5. Report to the user in **plain Spanish, one line per commit**, describing what was saved in their
   words — not the commit message:

   > Guardé dos cosas:
   > • La pantalla que lista las plantas
   > • El botón de "Regada" y el cálculo de la próxima fecha

6. **Do not push** unless the user asks. If they do, push and offer the PR (see
   `${CLAUDE_PLUGIN_ROOT}/skills/branch-pr/SKILL.md`).

## When they ask to "subir" it

"Subir" usually means push. Confirm what they want in one question:

> ¿Lo subo a GitHub para que quede respaldado, o lo dejamos guardado acá en tu compu?

If they have no GitHub set up, do not turn this into a setup project. Say their work is saved
locally and that GitHub can wait.
