---
name: _shared
description: "Referencias compartidas por las fases del flujo. No se invoca directamente."
disable-model-invocation: true
user-invocable: false
license: MIT
metadata:
  author: australis-ai
  version: "2.0"
---

## Purpose

Shared reference consumed by the phase agents (explore, design, apply, verify) and the reviewers.

| File | What it defines |
|---|---|
| `sdd-phase-common.md` | The contract every phase follows: executor role, the per-issue working folder, inputs, language, branch rule, project commands, memory, and the return envelope |

## Not Invokable

`_shared` is a support package only. Do not invoke it as a skill.
