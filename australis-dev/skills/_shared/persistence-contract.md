# Persistence Contract

There are no persistence modes to choose from, and the user is never asked about storage.

## The rule

> **Files always. Engram additionally, when it is alive.**

| Layer | When | Where |
|---|---|---|
| Files | Always, no exception | `.australis/` in the project root |
| Engram | Only when the `mem_search` tool exists in this session | `topic_key: sdd/{change-name}/{artifact}` |

## Availability check

The presence of the `mem_search` tool **is** the health check. The MCP server only registers its
tools if its binary actually started, so if the tool exists, memory works.

Never shell out to `where engram` or `engram --version` to decide this. It is slow, and on Windows
the PATH is exactly the thing that tends to be broken.

## Why files are the primary store, not the fallback

| | Files | Engram |
|---|---|---|
| Survives across sessions | via git and the working tree | ✅ |
| Survives compaction | ✅ (on disk) | ✅ |
| Keeps iteration history | ✅ git history | ❌ **`topic_key` upserts overwrite** |
| Shareable with a team | ✅ committed | ❌ local SQLite |
| The user can open and read it | ✅ `spec.md`, `tasks.md` | ❌ a database file |

The two decisive rows are the last three. Engram's upsert means re-running a phase destroys the
previous version — there is no revision trail. And a non-technical user can open `tasks.md` and
see the `[x]` marks; they cannot open a SQLite database.

Engram earns its place on cross-session recall and post-compaction recovery. It does not replace
the files.

## Conflict resolution

If a file and its Engram copy disagree, **the file wins**. It is the one under version control and
the one a human can inspect.

## Degradation

Engram being absent is not an error and must never be reported as one. Phases write files and
continue. The orchestrator mentions it at most **once per session**, in one plain line, at the end
of a build — never a stack trace, never a per-turn nag.

If `mem_save` fails mid-phase, note it in `risks` and carry on. The artifact is already on disk.
