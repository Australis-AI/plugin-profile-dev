# SDD Verify — Report Formats

Two audiences, two formats. Never mix them.

- **The user** gets the *Esto anda* checkpoint — Spanish, plain, no technical detail.
- **The file and the orchestrator** get the technical report, written to
  `.australis/cambios/<slug>/verify-report.md` (and to Engram as
  `sdd/{change-name}/verify-report` when `mem_search` exists).

---

## 1. User checkpoint — *Esto anda*

This is the numbered behaviour list the user approved at the spec checkpoint, copied verbatim
from `.australis/cambios/<slug>/spec.md`, with a mark appended to each line. Same wording,
same order, same numbering. The mark is the only edit.

```
Esto anda:

1. {línea textual del spec} ✅
2. {línea textual del spec} ❌
3. {línea textual del spec} ✅
```

A line is ✅ only when a covering test passed at runtime. No test means ❌.

### Failure block — one per ❌ line

Never a diagnosis. No cause, no test name, no file path, no error text. A choice, in the
user's own words:

```
No me salió esto: "los datos no se pierden al cerrar".
  a) Lo intento de otra forma (2 min más)
  b) Lo dejamos para después y seguimos
  c) Contame más de cómo lo esperabas
```

### Closing line

When everything passed and the change was closed, one line before the question:

```
Listo, lo dejé cerrado.
```

### Always end with the question

At most 3 options, each a real next move:

```
¿Qué sigue?
  a) Arreglamos lo que falló
  b) Lo dejamos así y seguimos con otra cosa
  c) Te muestro qué quedó hecho
```

### Banned from the user checkpoint

Raw stderr, stack traces, diffs, file trees, file paths, test names, coverage percentages,
exit codes, tool names, the words CRITICAL / WARNING / SUGGESTION, and any mention of
merges, folders, or where artifacts were written.

---

## 2. Compliance Statuses

- ✅ `COMPLIANT` — a covering test exists and passed.
- ❌ `FAILING` — a covering test exists and failed.
- ❌ `UNTESTED` — no covering test found.
- ⚠️ `PARTIAL` — the test passes but covers only part of the scenario.

---

## 3. Technical report template

~~~markdown
## Verification Report

**Change**: {change-name}
**Date**: {YYYY-MM-DD}
**Strict TDD**: {true | false} (from `.australis/proyecto.json`)

### Approved Behaviours
| # | Behaviour (verbatim from spec) | Result |
|---|--------------------------------|--------|
| 1 | {línea textual} | ✅ |
| 2 | {línea textual} | ❌ |

**Source of the list**: {named spec field | checkpoint section | scenario titles (fallback)}

### Completeness
| Metric | Value |
|--------|-------|
| Tasks total | {N} |
| Tasks complete | {N} |
| Tasks incomplete | {N} |

### Build & Tests Execution
**Build**: ✅ Passed / ❌ Failed
```text
{build command, exit code, relevant output}
```

**Tests**: ✅ {N} passed / ❌ {N} failed / ⚠️ {N} skipped
```text
{test command, exit code, failure detail}
```

**Coverage**: {N}% / threshold: {N}% → ✅ Above / ⚠️ Below / ➖ Not available

### Spec Compliance Matrix
| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| {REQ-01} | {Scenario} | `{file} > {test}` | ✅ COMPLIANT |
| {REQ-02} | {Scenario} | (none found) | ❌ UNTESTED |

**Compliance summary**: {N}/{total} scenarios compliant

### Correctness (Static Evidence)
| Requirement | Status | Notes |
|-------------|--------|-------|
| {Req name} | ✅ Implemented | {brief note} |

### Coherence (Design)
| Decision | Followed? | Notes |
|----------|-----------|-------|
| {Decision} | ✅ Yes | |

### Issues Found
**CRITICAL**: {list or None}
**WARNING**: {list or None}
**SUGGESTION**: {list or None}

### Verdict
{PASS / PASS WITH WARNINGS / FAIL}
{one-line reason}
~~~

When strict TDD is active, insert the TDD compliance, test layer distribution, changed-file
coverage, assertion quality, and quality metrics sections from `strict-tdd-verify.md`.

---

## 4. Closing record template

Written only when the change was closed, to
`.australis/hecho/<YYYY-MM-DD>-<slug>/archive-report.md` (and to Engram as
`sdd/{change-name}/archive-report` when `mem_search` exists).

~~~markdown
## Change Closed

**Change**: {change-name}
**Closed on**: {YYYY-MM-DD}
**Moved to**: `.australis/hecho/{YYYY-MM-DD}-{slug}/`
**Verdict at close**: {PASS | PASS WITH WARNINGS}

### Truth Merged into `.australis/proyecto.md`
| Capability | Action | Detail |
|------------|--------|--------|
| {capability} | Created / Updated | {N added, M modified, K removed requirements} |

**Requirements preserved untouched**: {N}

### Artifacts at Destination
- proposal.md {✅ / ➖ not produced}
- spec.md ✅
- design.md {✅ / ➖ not produced}
- tasks.md ✅ ({N}/{N} complete)
- apply-progress.md ✅
- verify-report.md ✅

### Engram
{topic keys written, or "Engram not available — files are the complete record"}

### Cycle Complete
Planned, implemented, verified, and closed. `.australis/cambios/{slug}/` no longer exists.
~~~

---

## 5. Rules for both formats

- The technical report never reaches the user's screen; the checkpoint never reaches the
  persisted report as a substitute for evidence. Write both.
- A `FAIL` verdict produces no closing record — the change stays in `.australis/cambios/`.
- Never invent a behaviour line. If the list cannot be found, use the spec's scenario titles
  verbatim and say so in the report's *Source of the list* field and in `risks`.
- Never soften a ❌ into a ⚠️ to make the checkpoint read better.
