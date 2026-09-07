# Artifact Layout

Everything the workflow produces lives under `.australis/` in the project root. Plain markdown and
one small JSON file — readable, diffable, and safe to commit.

```
.australis/
├── proyecto.md                     accumulated truth about this project
├── proyecto.json                   cached stack, commands, strict_tdd flag
├── skill-registry.md               index of available skills
├── cambios/
│   └── <slug>/                     the change in flight
│       ├── explore.md              from explore
│       ├── spec.md                 from spec — the contract the user approved (Spanish)
│       ├── tasks.md                from spec — ordered checklist (English)
│       ├── design.md               from design — technical decisions (English)
│       ├── apply-progress.md       from apply, when work spans batches
│       └── verify.md               from verify
└── hecho/
    └── <YYYY-MM-DD>-<slug>/        closed changes, moved here by verify
```

## Who writes what

| Phase | Writes | Reads |
|---|---|---|
| `explore` | `proyecto.json`, `skill-registry.md`, `cambios/<slug>/explore.md` | the codebase, `proyecto.md` |
| `spec` | `cambios/<slug>/spec.md`, `cambios/<slug>/tasks.md` | `explore.md` |
| `design` | `cambios/<slug>/design.md` | `spec.md`, `tasks.md` |
| `apply` | source code, `tasks.md` (`[x]` marks), `apply-progress.md` | `spec.md`, `tasks.md`, `design.md` |
| `verify` | `cambios/<slug>/verify.md`, then `proyecto.md`, then moves the folder to `hecho/` | everything above |

## Slug rules

Lowercase ASCII, hyphenated, no accents. `regar-plantas`, never `regar-plántas`.
Derive it from the change name the user gave. It is also the branch name suffix: `feat/<slug>`.

## Language inside artifacts

| File | Language | Why |
|---|---|---|
| `spec.md` | **Spanish** | It is the contract the user reads and approves |
| `proyecto.md` | **Spanish** | The user reads it |
| `tasks.md`, `design.md`, `verify.md` | **English** | Machine-consumed by later phases |
| `proyecto.json` keys and values | **English** | Configuration |

## Writing rules

- Create the change directory before writing into it.
- If a file already exists, **read it first and update it** — never overwrite blind.
- If the change directory already exists with artifacts, the change is being **continued**, not
  started. Resume from the last artifact present.
- Never modify anything under `hecho/`. It is the audit trail.

## `proyecto.json`

Written once by `explore` and reused. Re-detect only when the manifests or lockfiles changed.

```json
{
  "stack": "node",
  "commands": {
    "test": "npm test",
    "lint": "npm run lint",
    "typecheck": null,
    "format": null,
    "build": "npm run build"
  },
  "strict_tdd": true
}
```

Absent commands are `null`, never `""`. `strict_tdd` is auto-derived — true only when the project
already has a working test runner. It is never asked about.

## Resuming

The last artifact present in `cambios/<slug>/` tells you the next phase to run:

| Last present | Next |
|---|---|
| nothing | `explore` |
| `explore.md` | `spec` |
| `spec.md` + `tasks.md` | `design` |
| `design.md` | `apply` |
| `tasks.md` partly `[x]` | `apply` (continuation — read, merge, write) |
| all tasks `[x]` | `verify` |

## Should `.australis/` be committed?

Yes, by default. It is the project's planning record and it is worth having in git history.
`apply-progress.md` is the one exception — it is scratch state and can be gitignored.
