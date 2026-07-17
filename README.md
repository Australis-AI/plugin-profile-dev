# Australis dev profile — Claude Code plugin

Standalone distribution of the **Australis dev module**: a Claude Code plugin that
packages the development capability of the Australis harness — SDD workflow, PR/commit
flow, judgment-day review, and n8n workflow analysis — so it can be installed on any
machine and inherited across every working directory.

This repo is a **plugin marketplace** (`australis-dev`) with a single plugin
(`australis-dev`). It is intentionally separate from the main Australis AI-OS repo so
the dev profile can be shared without exposing the rest of the business (marketing,
ops, clients).

## What it provides

Once installed and enabled, these become available in **every** Claude Code session,
namespaced under `australis-dev:`:

- **SDD workflow** — `sdd-new`, `sdd-continue`, `sdd-ff`, `sdd-explore`, `sdd-propose`,
  `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`, `sdd-archive`,
  `sdd-init`, `sdd-onboard` (skills, commands, and one agent per phase).
- **PR / commit flow** — `branch-pr`, `chained-pr`, `work-unit-commits`, `issue-creation`.
- **Adversarial review** — `judgment-day` plus the `jd-judge-a` / `jd-judge-b` /
  `jd-fix-agent` agents.
- **n8n analysis** — `n8n-code-javascript`, `n8n-code-python`, `n8n-expression-syntax`,
  `n8n-node-configuration`, `n8n-validation-expert`, `n8n-workflow-patterns`,
  `n8n-mcp-tools-expert`.

## Why a plugin (and why user scope)

Claude Code does **not** inherit project skills/agents/commands by folder hierarchy —
opening Claude inside a nested repo does not pick up skills from a parent `.claude/`.
A **user-scope** plugin is the mechanism that is inherited across all directories, is
not duplicated, and can be toggled on/off to hand the harness to a non-dev.

## Install

Requires Claude Code (`claude` CLI). Run from anywhere:

```bash
claude plugin marketplace add Australis-AI/plugin-profile-dev
claude plugin install australis-dev@australis-dev --scope user
```

> `marketplace add` clones the repository's **default branch**. Keep the plugin and
> `marketplace.json` on the default branch so remote installs resolve.

Verify:

```bash
claude plugin list        # australis-dev@australis-dev — Scope: user — enabled
```

Skills appear as `australis-dev:sdd-new`, `australis-dev:branch-pr`, etc.

## Give / take the module to a non-dev

The whole module is a single switch — no uninstall needed:

```bash
claude plugin disable australis-dev@australis-dev   # hand the harness to a non-dev
claude plugin enable  australis-dev@australis-dev   # turn it back on
```

To remove entirely:

```bash
claude plugin uninstall australis-dev@australis-dev
claude plugin marketplace remove australis-dev
```

## Update

After new versions are pushed to this repo:

```bash
claude plugin marketplace update australis-dev
claude plugin update australis-dev@australis-dev
```

Within a session, run `/reload-plugins` to pick up local changes to skills; agents,
commands, hooks, and the manifest need a session restart.

## Repo layout

```
plugin-profile-dev/
├── .claude-plugin/
│   └── marketplace.json     # marketplace "australis-dev"
└── australis-dev/           # the plugin
    ├── .claude-plugin/
    │   └── plugin.json
    ├── skills/
    ├── agents/
    ├── commands/
    └── README.md
```

## Not included

The dev session's `orchestrator.md` and `dev-context.md` live in the main Australis
AI-OS repo and are read on demand there; they are not part of this plugin. If a fully
self-contained profile is needed, migrate them here as skills.
