---
name: sdd-explore
description: "Explora el proyecto y la idea antes de tocar código: detecta el stack, arma el registro de skills y devuelve qué existe, qué se toca y por dónde ir. Se dispara con: quiero agregar X, investigá cómo está hecho esto, arrancá un cambio nuevo."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "4.0"
  delegate_only: true
---

> **ORCHESTRATOR GATE**: If you loaded this skill via the `skill()` tool, you are
> the ORCHESTRATOR — STOP. Do NOT execute these instructions inline. Delegate to
> the dedicated `sdd-explore` sub-agent using your platform's delegation primitive
> (e.g., `task(...)`, sub-agent invocation, etc.). This skill is for EXECUTORS
> only.

## Executor Override

If you ARE the `sdd-explore` sub-agent (NOT the orchestrator), the gate above does NOT apply to you. Continue with the phase work below. Do NOT delegate. Do NOT call the Skill tool. You are the executor — execute.

## Activation Contract

You are the FIRST phase of the SDD chain (`explore → spec → design → apply → verify`). In ONE round trip you: detect the project, cache that detection, build the skill registry, explore the requested change, and return a short brief. There is no separate init phase — if the project has never been detected, you detect it now.

Inputs the orchestrator gives you: the request to explore, and optionally a `change_name`. Everything else you resolve yourself.

## Hard Rules

- **Never ask the user how to persist.** Artifacts ALWAYS go to files under `.australis/` in the project root. Additionally save to Engram when it is available. There are no persistence modes to choose.
- **Engram availability = tool presence.** If `mem_search` is in your tool list, Engram is available. Do NOT shell out, do NOT probe a CLI, do NOT ask.
- **Never ask about strict TDD.** Derive it: test runner found → `strict_tdd: true`; no test runner → `strict_tdd: false`.
- **Detect, never execute.** Use `Bash` only to inspect the filesystem (list files, read sizes/timestamps). NEVER run the project's test, build, lint, or install commands. You record the commands; `sdd-verify` runs them.
- **Never modify project code.** The only files you may write are the four `.australis/` artifacts listed below.
- **Read real code.** Never infer a stack, a command, or an architecture from a file name alone — open the file.
- **Language split** (not negotiable):
  - `.australis/proyecto.json` → keys and enum values exactly as specified in `references/detection.md` (English identifiers).
  - `.australis/proyecto.md`, `.australis/cambios/{slug}/explore.md`, and every envelope field the orchestrator shows the user → **Spanish, plain, no jargon**. No English section titles in those files.
  - `.australis/skill-registry.md` → an index; keep each skill's own `name`/`description` text verbatim.
- **The brief is ≤ 300 words.** Count them. If you are over, cut approaches, not the recommendation.
- **The checkpoint fields carry prose, never artifacts.** Never put a spec, a file tree, a diff, a command, or a code block into `checkpoint_entendi` / `checkpoint_no_va_a`.

## Decision Gates

| Condition | Action |
|---|---|
| `.australis/proyecto.json` missing or unreadable | Run full detection (Step 2a), then write it. |
| It exists AND `fingerprint` matches the current one | **Reuse it. Skip detection entirely.** Do not re-open manifests. |
| It exists AND `fingerprint` differs | Re-detect, rewrite it, preserve `first_detected_at`. |
| Test runner detected | `strict_tdd: true` |
| No test runner detected | `strict_tdd: false`; add "no hay tests automatizados" to `risks`. |
| `.australis/skill-registry.md` missing, OR detection just re-ran, OR orchestrator passed `refresh_registry: true` | Rebuild the registry (Step 3). |
| Otherwise | Reuse the existing registry file as-is. |
| `mem_search` present in your tool list | Persist to files AND Engram. |
| `mem_search` absent | Persist to files only. Not a risk — say so in `artifacts`. |
| No `change_name` given | Derive a slug: kebab-case, ASCII only (strip accents), max 5 words, from the request. |
| Request too vague to scope | `status: blocked`. Put ONE short Spanish question in `executive_summary`. Ask nothing else. |

## Artifact Layout

```
.australis/
├── proyecto.md                    # accumulated project truth (Spanish, human-readable)
├── proyecto.json                  # cached stack/commands detection (English keys)
├── skill-registry.md              # skill index — name, trigger, scope, exact path
└── cambios/
    └── {slug}/
        └── explore.md             # this phase's brief (Spanish, ≤300 words)
```

## Execution Steps

### Step 1 — Load skills

Follow **Section A** of `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md`.

### Step 2 — Resolve project detection (cache-aware)

Compute the current fingerprint FIRST, then decide. The fingerprint is a map of every manifest/lockfile that exists, to `"{bytes}:{mtime-epoch}"`. The file list and the fingerprint recipe are in `references/detection.md`.

Read `.australis/proyecto.json`. Compare its `fingerprint` to the one you just computed. Apply the Decision Gates above.

**Step 2a — full detection** (only when the gate says to):

1. Open the manifests, CI config, and lint/test config you found. Identify: languages, runtime, package manager, frameworks.
2. Identify the architecture in one paragraph — layout, entry points, where the real logic lives.
3. Identify conventions: source root, test layout, naming, import style.
4. Detect the commands: `test`, `test_watch`, `coverage`, `lint`, `typecheck`, `format`, `build`. Record the exact invocation, or `null` if absent. Never invent one.
5. Detect test layers (unit / integration / e2e) and set `strict_tdd`.
6. Write `.australis/proyecto.json` per the schema in `references/detection.md`.
7. Update `.australis/proyecto.md` — the accumulated Spanish truth about the project. Rewrite the stack/convention sections; keep prior notes that are still accurate.

### Step 3 — Build the skill registry

Per the Decision Gates. Scan targets, exclusions, and the row format are in `references/detection.md`. Write `.australis/skill-registry.md`. The registry is an **index of exact `SKILL.md` paths** — never a summary of what the skills say.

### Step 4 — Explore the requested change

This is the actual investigation. Read real code:

```
INVESTIGATE:
├── Entry points and the modules the request touches
├── Existing behavior that already does part of this
├── Tests that cover the affected area
├── Patterns already in use that the change must follow
└── Coupling, dependencies, and constraints
```

Then settle on ONE recommended approach. Mention an alternative only if it is genuinely competitive — one line each, no comparison table.

### Step 5 — Persist

**MANDATORY — the pipeline breaks without it.**

1. Write `.australis/cambios/{slug}/explore.md` with the brief from Step 6. Always.
2. If Engram is available, additionally save (per **Section C** of `sdd-phase-common.md`):

| What | `title` / `topic_key` | `type` |
|---|---|---|
| Project context (stack, conventions, commands, `strict_tdd`) | `sdd-init/{project}` | `architecture` |
| Skill registry | `skill-registry` | `config` |
| This exploration | `sdd/{slug}/explore` | `architecture` |

`sdd-init/{project}` keeps that exact key for backward compatibility with already-saved memories — do not rename it. Set `capture_prompt: false`; if the tool schema does not expose the field, omit it rather than failing.

### Step 6 — Return

Write the brief, then the envelope. Your final output must be TEXT, not a tool call (**Section D** of `sdd-phase-common.md`).

## Output Contract

### The brief — ≤ 300 words, Spanish

Identical content goes to `.australis/cambios/{slug}/explore.md` and into `detailed_report`.

```markdown
## Exploración: {título en español}

### Cómo está hoy
{Cómo funciona hoy la parte del sistema que toca este pedido.}

### Qué se toca
- `ruta/al/archivo.ext` — {por qué}

### Por dónde ir
{El enfoque recomendado y por qué. Si hay una alternativa real, una línea.}

### Qué puede salir mal
- {riesgo}
```

### The envelope

Per **Section D** of `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md`, plus two checkpoint fields this phase adds.

| Field | Content |
|---|---|
| `status` | `success` \| `partial` \| `blocked` |
| `executive_summary` | 1–2 sentences in Spanish. If `blocked`, the single clarifying question instead. |
| `detailed_report` | The ≤300-word brief above. |
| `artifacts` | Every path written, plus Engram topic keys if saved. Say `solo archivos` when Engram was absent. |
| `next_recommended` | `sdd-spec` — always. |
| `risks` | Spanish. Include `strict_tdd: false` here when there is no test runner. |
| `skill_resolution` | `paths-injected` \| `fallback-registry` \| `fallback-path` \| `none` |
| **`checkpoint_entendi`** | **1–5 bullets, plain Spanish, one line each.** What the change will do, in the user's words. This is what the orchestrator shows as *"Esto entendí"*. |
| **`checkpoint_no_va_a`** | **1–4 bullets, plain Spanish.** What this change explicitly does NOT include. This is the *"Por ahora NO va a…"* block. Adjacent work you deliberately left out — never a list of files or steps. |

Both checkpoint fields are MANDATORY when `status` is `success` or `partial`. The orchestrator renders them verbatim to the user, so they must read as sentences a non-technical person understands — no paths, no commands, no type names.

Example:

```markdown
**Status**: success
**Summary**: Exploré cómo se manejan hoy las sesiones y encontré el punto donde conviene enganchar el login con Google.
**Artifacts**: `.australis/proyecto.json` | `.australis/skill-registry.md` | `.australis/cambios/login-google/explore.md` | Engram `sdd/login-google/explore`
**Next**: sdd-spec
**Risks**: No hay tests automatizados en el proyecto (strict_tdd: false).
**Skill Resolution**: paths-injected — 2 skills

**Esto entendí**:
- Vas a poder entrar a la app con tu cuenta de Google, sin crear contraseña.
- Quien ya tiene cuenta con email va a poder vincular su Google a esa misma cuenta.
- La sesión va a durar lo mismo que dura hoy.

**Por ahora NO va a**:
- Sumar otros proveedores como GitHub o Apple.
- Tocar cómo se recupera una contraseña olvidada.
```

## References

- [references/detection.md](references/detection.md) — fingerprint recipe, `proyecto.json` schema, detection checklist, registry scan rules and row format.
- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/sdd-phase-common.md` — Sections A (skill loading), C (persistence), D (return envelope).
- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/engram-convention.md` — Engram artifact naming.
