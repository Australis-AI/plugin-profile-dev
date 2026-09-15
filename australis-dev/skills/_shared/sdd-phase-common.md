# Phase — Common Protocol

Boilerplate identical across all phase skills. Sub-agents MUST load this alongside their
phase-specific `SKILL.md`.

**Executor boundary**: every phase agent is an EXECUTOR, not an orchestrator. Do the phase work
yourself. Do NOT launch sub-agents, do NOT call `delegate`/`task`, and do NOT bounce work back
unless your phase skill explicitly says to stop and report a blocker.

The five phases are: **explore → spec → design → apply → verify**.

## A. Skill Loading

1. Check whether the orchestrator injected a `## Skills to load before work` block in your launch
   prompt. If yes, read those exact `SKILL.md` files before task-specific work.
2. If no skills block was provided, check for `SKILL: Load` instructions. If present, load those.
3. If neither was provided, fall back to the skill registry:
   a. `mem_search(query: "skill-registry", project: "{project}")` — if found,
      `mem_get_observation(id)` for the full content
   b. Otherwise read `.australis/skill-registry.md` from the project root
   c. Match triggers to your task and read the exact `SKILL.md` paths listed.
4. If no registry exists, proceed with your phase skill alone.

The preferred path is (1). Searching the registry is SKILL LOADING, not delegation. If
`## Skills to load before work` is present, IGNORE redundant `SKILL: Load` instructions.

## B. Artifact Retrieval

Artifacts live in **two places**. Files are always present. Engram is present only when the
`mem_search` tool exists in this session — that tool's presence IS the availability check. Never
shell out to `where engram`.

### Files — always try this first

```
.australis/proyecto.md                      accumulated project truth
.australis/proyecto.json                    cached stack, commands, strict_tdd
.australis/cambios/{change-name}/explore.md
.australis/cambios/{change-name}/spec.md    the numbered behaviours the user approved
.australis/cambios/{change-name}/tasks.md
.australis/cambios/{change-name}/design.md
.australis/cambios/{change-name}/apply-progress.md
.australis/cambios/{change-name}/verify.md
```

Read the ones your phase declares as inputs. A missing required input is a `blocked` status — say
which file was missing.

### Engram — when available, for cross-session and post-compaction recovery

**CRITICAL**: `mem_search` returns 300-character PREVIEWS, not full content. You MUST call
`mem_get_observation(id)` for EVERY artifact. **Skipping this produces wrong output.**

Run all searches in parallel, then all retrievals in parallel:

```
mem_search(query: "sdd/{change-name}/{artifact-type}", project: "{project}") → save ID
mem_get_observation(id: {saved_id}) → full content (REQUIRED)
```

Never use a search preview as source material.

If a file and an Engram copy disagree, **the file wins** — it is the one under version control and
the one the user can read.

## C. Artifact Persistence

Every phase that produces an artifact MUST persist it. Skipping this breaks the pipeline —
downstream phases will not find your output.

**The rule has no modes and is never a user question:**

1. **Write the file. Always.** Under `.australis/`, at the path listed in Section B. Create parent
   directories as needed.
2. **Additionally call `mem_save`** — only when the `mem_search` tool exists in this session.

```
mem_save(
  title: "sdd/{change-name}/{artifact-type}",
  topic_key: "sdd/{change-name}/{artifact-type}",
  type: "architecture",
  project: "{project}",
  capture_prompt: false,
  content: "{your full artifact markdown}"
)
```

`topic_key` enables upserts — saving again updates rather than duplicates. Note that this means
Engram keeps no revision history; the file's git history is the record.

`capture_prompt: false` is mandatory here because these are automated pipeline outputs, not human
memory saves. If an older Engram schema rejects or does not expose the field, omit it rather than
failing.

If `mem_save` fails, **do not fail the phase.** The file is written; note it in `risks` and carry on.

## D. Return Envelope

> **CRITICAL — response ordering**: your FINAL output MUST be text (the envelope), NOT a tool call.
> If you need `mem_save`, call it BEFORE your final text response. Do NOT call
> `mem_session_summary` — that is for top-level agents only. When a sub-agent's last action is a
> tool call, the parent receives only the tool result and your analysis is lost.

Every phase MUST return:

| Field | Meaning |
|---|---|
| `status` | `success`, `partial`, or `blocked` |
| `executive_summary` | 1–3 sentences on what was done |
| `artifacts` | Files written, plus Engram topic keys when saved |
| `next_recommended` | The next phase, or `none` |
| `risks` | Risks discovered, or `None` |
| `skill_resolution` | `paths-injected`, `fallback-registry`, `fallback-path`, or `none` |

### User-facing checkpoint fields

Three phases additionally carry the text the orchestrator shows the user. These are **Spanish,
plain, no jargon** — never a spec, a diff, a stack trace, or a file tree. Rioplatense register
with voseo (*vos, tenés, podés*), never *tú/tienes*: the output style does not reach you, so the
register has to come from here.

| Phase | Field | Content |
|---|---|---|
| `explore` | `checkpoint_entendi` | 1–5 one-line scope bullets |
| `explore` | `checkpoint_no_va_a` | 1–4 bullets of what is explicitly out of scope |
| `spec` | `user_checkpoint` | The numbered behaviour list verbatim, plus one estimate line |
| `verify` | `user_checkpoint` | That same list, same wording and order, with ✅/❌ per item |

`design` and `apply` have **no** user checkpoint — they run back to back between the spec and
verify checkpoints. Do not invent one.

### Example

```markdown
**Status**: success
**Summary**: Spec written for `regar-plantas`. 5 behaviours, 11 tasks.
**Artifacts**: `.australis/cambios/regar-plantas/spec.md`, `.australis/cambios/regar-plantas/tasks.md` | Engram `sdd/regar-plantas/spec`, `sdd/regar-plantas/tasks`
**Next**: sdd-design
**Risks**: None
**Skill Resolution**: paths-injected — 2 skills
```

## E. Review Workload Guard

The workflow protects reviewer cognitive load, not just task generation.

- The default review budget is **400 changed lines** (`additions + deletions`).
- `spec` MUST forecast whether the planned work will exceed it, emitting these exact plain-text
  lines so downstream phases can grep them:
  - `400-line budget risk: Low|Medium|High`
  - `Chained PRs recommended: Yes|No`
  - `Decision needed before apply: No`
  - `Chain strategy: stacked-to-main`
- The last two are **fixed constants**, emitted verbatim so downstream phases can grep them.
  Delivery and chain strategy are decided here, not asked — the question is unanswerable for a
  non-technical user and stalls the session.
- When the risk is `High`, `apply` implements the next autonomous slice using work-unit commits —
  clear start, clear finish, verifiable, reversible — rather than the whole change at once.
- Surface this to the user only as one plain sentence at the spec checkpoint, e.g. *"esto quedó
  grande, lo hago en dos partes para que se pueda revisar bien"*. Never present a strategy menu.

See `${CLAUDE_PLUGIN_ROOT}/skills/chained-pr/SKILL.md` and
`${CLAUDE_PLUGIN_ROOT}/skills/work-unit-commits/SKILL.md`.
