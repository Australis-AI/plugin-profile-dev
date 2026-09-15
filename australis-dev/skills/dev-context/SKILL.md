---
name: dev-context
description: "El criterio técnico con el que Australis construye software: arquitectura, testing y cuándo aflojar la vara. Trigger: cómo estructuro esto, qué arquitectura conviene, revisá este diseño, decisiones técnicas."
license: MIT
metadata:
  author: australis-ai
  version: "2.0"
---

# Technical Judgment

The technical bar the work is held to. It is injected into design, apply, verify and review.
It does not describe the workflow (that is the orchestrator) and it does not describe how to talk
to the user (that is the output style: level, non-negotiables, cost protocol).

## Architecture

- **Screaming architecture.** The folder structure says what the system does, not which framework
  it uses. `plants/`, `watering/`, `reminders/` tell you everything; `controllers/`, `services/`,
  `models/` tell you nothing.
- **Domain apart from infrastructure.** Business rules do not import the database, the HTTP
  framework or the UI. Dependencies point inward.
- **Frontend:** one responsibility per component; separate what fetches data from what renders it.
- **Follow the project.** In an existing repo, its established patterns beat generic best
  practice. Change a pattern only on purpose, in its own issue.

## Testing

- **Testing is part of the work.** The test states the expected behaviour before the
  implementation is wired, whenever the project has a runner.
- **Test behaviour, not implementation.** A test that breaks on a harmless refactor is a bad test.
- **Evidence is executed.** A behaviour is done when a test covering it passes, or, where a test
  makes no sense (copy, styling, config), when a command, request or output was actually run and
  recorded.
- **Baseline.** Failures that already existed on the default branch are not yours to hide and not
  a reason to block: record them in an issue and in Risks. New failures block.

## Principles

- **Concepts before code.** Understand the problem before writing the solution. When a request
  has no understanding behind it, ask the one question that unblocks it.
- **Explain the technical why** in every decision and correction you record (design Decisions,
  PR body, review findings). A decision without a reason teaches nothing and gets reversed.
- **AI is a tool.** The human directs; you execute and you say when what they asked for will hurt.

## Reading the room on scope

Not everything deserves the full architecture. A one-file script for a personal task does not
need domain boundaries, and imposing them is its own failure of judgment.

Apply the full standard when the thing will be maintained, extended, or read by someone else.
Loosen it when the code is genuinely disposable, and say which mode you are in, once.
