# Engram Artifact Convention

Applies **only when Engram is available** — that is, when the `mem_search` tool exists in this
session. Files under `.australis/` are written regardless; see
`${CLAUDE_PLUGIN_ROOT}/skills/_shared/persistence-contract.md`.

The critical Engram calls are inlined in each phase's `SKILL.md`. This file is reference.

## Naming

Every artifact uses the same deterministic key for both `title` and `topic_key`:

```
sdd/{change-name}/{artifact-type}
```

`{change-name}` is the slug — lowercase ASCII, hyphenated, no accents. The same slug names the
folder under `.australis/cambios/` and the branch `feat/{change-name}`.

## Keys

| Artifact | Topic key | Written by |
|---|---|---|
| Project context | `sdd-init/{project}` | `explore` |
| Skill registry | `skill-registry` | `explore` |
| Exploration | `sdd/{change-name}/explore` | `explore` |
| Spec | `sdd/{change-name}/spec` | `spec` |
| Tasks | `sdd/{change-name}/tasks` | `spec` |
| Design | `sdd/{change-name}/design` | `design` |
| Apply progress | `sdd/{change-name}/apply-progress` | `apply` |
| Verify report | `sdd/{change-name}/verify-report` | `verify` |
| Closing record | `sdd/{change-name}/archive-report` | `verify` |

`sdd-init/{project}` keeps its historical name deliberately — the `init` phase was folded into
`explore`, but renaming the key would orphan project context already saved on existing machines.

## Reading — two steps, always

`mem_search` returns **300-character previews**. Using a preview as source material produces wrong
output.

```
1. mem_search(query: "{topic_key}", project: "{project}")  → observation ID
2. mem_get_observation(id: {id})                           → full content (REQUIRED)
```

Run multiple searches in parallel, then multiple retrievals in parallel. Never sequentially.

## Writing

```
mem_save(
  title:          "sdd/{change-name}/{artifact-type}",
  topic_key:      "sdd/{change-name}/{artifact-type}",
  type:           "architecture",
  project:        "{project}",
  capture_prompt: false,
  content:        "{full artifact markdown}"
)
```

`topic_key` makes the save an **upsert**: re-running a phase updates the record instead of
duplicating it. The consequence is that Engram keeps no revision history — the file's git history
is the trail.

`capture_prompt: false` is required: these are automated pipeline outputs, not human memory saves.
If an older Engram schema does not expose the field, omit it rather than failing.

## Failure is not fatal

If `mem_save` fails, the artifact is already on disk. Note it in `risks` and continue. Never fail a
phase because memory was unavailable, and never surface the failure to the user as an error.
