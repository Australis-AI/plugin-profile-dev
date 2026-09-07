---
name: issue-creation
description: "Anotar pendientes y bugs como issues de GitHub, claros y accionables. Trigger: crear un issue, reportar un bug, anotar un pendiente, esto lo dejamos para después."
license: MIT
metadata:
  author: australis-ai
  version: "2.0"
---

# Issues

Issues are how a project remembers what is still pending. For someone who does not program, they
replace "me acuerdo que había algo del botón".

This applies to **the user's own repository**. Do not assume it has issue templates, a label
taxonomy, or an approval workflow. Most do not. **Never block work waiting for an approval or a
label that this repo does not define** — that is a dead end with no maintainer on the other side.

---

## Hard Rules

1. **Never** require a `status:approved`-style gate before work can start. If the user wants
   something built, build it.
2. **Never** create an issue just to satisfy a convention. Issues exist to remember real pending
   work.
3. **Never** invent a template file. Write the body directly.
4. Search for duplicates before creating.
5. If `gh` is not authenticated or there is no GitHub remote, **do not mention issues at all** —
   note the pending item in `.australis/proyecto.md` instead.

---

## When to create one

| Situation | Action |
|---|---|
| The user says "esto lo dejamos para después" | Offer to note it: *"¿Lo anoto como pendiente para no perderlo?"* |
| Something broke and is not being fixed now | Create a bug issue |
| A behaviour was cut from scope at checkpoint 2 | Offer to note it after the build closes |
| The user asks directly | Create it |
| The user wants it built now | **Just build it.** No issue needed. |

---

## Before creating

```bash
gh issue list --search "<keywords>" --state all --limit 10
```

If a close match exists, show it and ask whether to add to that one instead.

---

## Body format

Short, plain, and specific. Spanish, because the user reads it.

### For a bug

```markdown
## Qué pasa
<what the user sees, in their words>

## Cómo repetirlo
1. <step>
2. <step>

## Qué debería pasar
<expected>
```

### For a pending feature

```markdown
## Qué falta
<the behaviour, one or two sentences>

## Para qué sirve
<why it matters — the problem it solves>

## Listo cuando
- [ ] <observable, checkable condition>
```

The **"Listo cuando"** section is the important one: it is the same kind of testable statement as
the behaviours in a spec, so the issue can flow straight into a build later.

---

## Creating it

```bash
gh issue create --title "<type>: <short description>" --body-file <file>
```

Title uses the conventional-commit type prefix (`feat:`, `fix:`, `docs:`, `chore:`) so it lines up
with branches and commits later.

Add labels **only if the repository already defines them**:

```bash
gh label list
```

If it defines none, create the issue without labels. Do not create a label taxonomy uninvited.

---

## After creating

Tell the user in one line, in Spanish, and give them the number:

> Lo anoté como pendiente — issue #12. Cuando lo quieras hacer, decime "seguí con el 12".

When work later starts on that issue, `branch-pr` links it with `Closes #N` in the PR body.
