# Detection Reference — sdd-explore

Everything the explore phase needs to detect a project once, cache it, and index skills.

## 1. Fingerprint recipe

The fingerprint decides whether cached detection is still valid. Build it BEFORE reading `.australis/proyecto.json`.

For each of these paths that EXISTS at the project root (or one level down for monorepo workspaces), add an entry `"{path}": "{bytes}:{mtime-epoch-seconds}"`:

```
package.json          package-lock.json   pnpm-lock.yaml    yarn.lock       bun.lockb
deno.json             go.mod              go.sum            Cargo.toml      Cargo.lock
pyproject.toml        poetry.lock         uv.lock           requirements.txt
Gemfile               Gemfile.lock        composer.json     composer.lock
Directory.Packages.props   *.csproj       Makefile          justfile
```

Sort keys alphabetically so the map is stable. A missing file is simply absent from the map — never an entry with a null value.

`fingerprint` matches when the two maps are byte-identical (same keys, same values). Any difference — added file, removed file, changed size, changed mtime — means re-detect.

Cheap way to gather it in one call (adapt to the shell available):

```bash
for f in package.json pnpm-lock.yaml go.mod pyproject.toml Cargo.toml; do
  [ -f "$f" ] && stat -c '%n %s %Y' "$f"
done
```

## 2. `proyecto.json` schema

Keys and enum values are English and fixed. Values that describe the project in prose are Spanish.

```json
{
  "schema_version": 1,
  "project": "{engram/git project name, lowercase}",
  "first_detected_at": "YYYY-MM-DD",
  "detected_at": "YYYY-MM-DD",
  "stack": {
    "languages": ["typescript"],
    "runtime": "node 22",
    "package_manager": "pnpm",
    "frameworks": ["react", "vite"]
  },
  "architecture": "{un párrafo en español}",
  "conventions": {
    "source_root": "src/",
    "test_layout": "{p. ej. tests junto al código, sufijo .test.ts}",
    "naming": "{convención observada}",
    "notes": "{lo que un agente nuevo necesita saber para no romper el estilo}"
  },
  "commands": {
    "test": "pnpm test",
    "test_watch": "pnpm test --watch",
    "coverage": "pnpm test --coverage",
    "lint": "pnpm lint",
    "typecheck": "pnpm tsc --noEmit",
    "format": "pnpm format",
    "build": "pnpm build"
  },
  "test_runner": {
    "present": true,
    "framework": "vitest",
    "layers": { "unit": true, "integration": false, "e2e": false }
  },
  "strict_tdd": true,
  "fingerprint": { "package.json": "2481:1757203200" }
}
```

Rules:

- Every key in `commands` is present. Use `null` — never `""`, never a guess — when the command does not exist.
- `strict_tdd` mirrors `test_runner.present`. Nothing else sets it. It is never asked.
- `first_detected_at` is written once and preserved across re-detections. `detected_at` updates every time.
- `project` must match the name used for Engram saves so `sdd-init/{project}` resolves.

## 3. Detection checklist

**Stack and commands** — read, do not run:

| Source | What to pull |
|---|---|
| `package.json` | `scripts`, `packageManager`, `engines`, dependency names |
| `pyproject.toml`, `pytest.ini`, `tox.ini` | build backend, test config, ruff/mypy/black config |
| `go.mod`, `Makefile` | module path, Go version, make targets |
| `Cargo.toml` | edition, workspace members |
| CI config (`.github/workflows/`, `.gitlab-ci.yml`) | the commands CI actually runs — the most reliable source |
| Lint/format config (`eslint.*`, `biome.json`, `.ruff.toml`, `.prettierrc`) | the quality commands |

CI config beats `package.json` scripts when they disagree — CI is what actually has to pass.

**Test layers**:

| Layer | Signals |
|---|---|
| Unit | vitest, jest, pytest, `go test`, cargo test, xunit |
| Integration | testing-library, supertest, httpx, `httptest`, testcontainers, `WebApplicationFactory` |
| E2E | playwright, cypress, puppeteer, selenium, chromedp |

**Coverage**: `--coverage` flags, `c8`, `nyc`, `pytest-cov`, `go test -cover`, `coverlet`.

**Architecture**: find the entry points, then follow them one level in. Say where the real logic lives and how the layers are split. One paragraph — this is orientation for the next agent, not documentation.

## 4. `proyecto.md` — accumulated truth

Spanish, human-readable, overwritten section by section (never blindly appended). Suggested shape:

```markdown
# {proyecto}

## Qué es
{una o dos frases}

## Stack
{lenguajes, runtime, frameworks, gestor de paquetes}

## Cómo está organizado
{arquitectura en un párrafo, dónde está cada cosa}

## Convenciones
{cómo se nombran las cosas, dónde van los tests, estilo de imports}

## Comandos
| Para | Comando |
|---|---|
| Tests | `...` |
| Lint | `...` |
| Tipos | `...` |
| Formato | `...` |
| Build | `...` |

## Historial de exploraciones
- {fecha} — {slug del cambio} — {una línea}
```

Keep prior notes that are still true. Delete lines that detection just contradicted — do not annotate them as outdated.

## 5. Skill registry scan rules

**Scan targets** (in this order; project-level wins on name collisions):

1. `${CLAUDE_PLUGIN_ROOT}/skills/`
2. `{project-root}/.claude/skills/`
3. `{project-root}/skills/`
4. `{project-root}/.australis/skills/`

**Exclusions**: skip `sdd-*`, `_shared`, and `skill-registry` itself. Deduplicate by skill `name`.

**Per skill**, read only the `SKILL.md` frontmatter and extract: `name`, the trigger text from `description`, the absolute or `${CLAUDE_PLUGIN_ROOT}`-rooted path, and the scope (`plugin` | `project`).

**Also index project convention files** when present: `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `GEMINI.md`, `.github/copilot-instructions.md`. When one of them is an index that points at other files, list both the index and the files it references.

**Row format** for `.australis/skill-registry.md`:

```markdown
# Skill Registry

_Generado por sdd-explore — {fecha}_

| Skill | Cuándo aplica | Scope | Path |
|---|---|---|---|
| `branch-pr` | creating, opening, or preparing PRs | plugin | `${CLAUDE_PLUGIN_ROOT}/skills/branch-pr/SKILL.md` |
```

The registry is an **index**, not a summary. Delegators pass these exact paths to sub-agents, and the sub-agent reads the full `SKILL.md` — so the author's intent is never degraded by a generated paraphrase. Keep each skill's own trigger wording verbatim.

## 6. LLM-first skill criteria

Applied when judging or writing a skill found during the scan.

- A skill is a runtime instruction contract, not human documentation.
- Structure: frontmatter, Activation Contract, Hard Rules, Decision Gates, Execution Steps, Output Contract, References.
- `description` stays quoted, one physical line, trigger-first, ≤ 250 characters.
- Body targets 180–450 tokens; examples, schemas, and edge cases move into local `references/`.
- References resolve locally and stay stable relative to the skill directory.
- Quality gates: hard rules are observable, decision gates cover real forks, the output contract states exactly what to return.
