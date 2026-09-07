---
name: _shared
description: "Referencias compartidas por las fases del flujo. No se invoca directamente."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "1.0"
---

## Purpose

Shared reference documents consumed by the five phase skills
(`explore`, `spec`, `design`, `apply`, `verify`) and by the orchestrator.

| File | What it defines |
|---|---|
| `sdd-phase-common.md` | The A/B/C/D/E contract every phase follows: skill loading, artifact retrieval, persistence, the return envelope, and the review workload guard |
| `persistence-contract.md` | Files always, Engram additionally when alive. No modes, no user question |
| `artifacts-convention.md` | The `.australis/` layout, slug rules, per-phase read/write table, language split, resume table |
| `engram-convention.md` | Topic keys and the mandatory two-step read |
| `skill-resolver.md` | How a delegator resolves and injects exact skill paths |

## Not Invokable

`_shared` is a support package only. Do not invoke it as a skill.
