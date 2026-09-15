# Verify report format

`verify.md` has two audiences. The top block is what the orchestrator shows the user at the
"Esto anda" gate (Spanish). The rest is technical evidence and feeds the PR's Verification section
(English).

```markdown
# Verify: #<N> <title>

## Gate (Spanish — shown to the user)

1. <criterio textual del issue> ✅
   Evidencia: <una línea llana: "la prueba de cargar un gasto pasa" / "abrí la app y el total cambió a $1.500">
2. <criterio textual del issue> ❌
   Falta: <una línea llana de qué no se cumple, sin nombres de archivos ni errores>

## Verdict
PASS | PASS WITH WARNINGS | FAIL — <n> CRITICAL, <n> WARNING

## Verification (English — copied into the PR body)

| # | Criterion | Evidence | Result |
|---|---|---|---|
| 1 | <criterion> | `<test file>::<test name>` passed / ran `<command>` → `<output>` | ✅ |
| 2 | <criterion> | no covering test | ❌ |

- Tests: `<command>` → exit <code>, <passed>/<total> passed
- Build: `<command>` → exit <code>
- Lint: `<command>` → exit <code>, <n> findings introduced
- New failures vs baseline: <none | list>
- Inherited failures (baseline): <none | list>

## Tasks
<done>/<total> — incomplete: <list or "none">

## Design coherence
<deviations and whether they matter — or "Matches design">

## Issues
### CRITICAL
- <...>
### WARNING
- <...>
### INFO
- <...>
```

Rules for the gate block:
- Criteria copied character for character from the issue, same order and numbering.
- Evidence lines in plain Spanish with voseo. No test names, paths, stack traces or English terms.
- ✅ requires evidence from this run; untested is ❌.
