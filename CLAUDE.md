# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code **plugin + marketplace** (`san-workflow` in marketplace `san-marketplace`) made entirely of Markdown and two JSON manifests. There is no build, lint, or test suite. "Code" here means skill/agent/rule prompts.

Local check before pushing:

```bash
claude plugin validate .          # validate .claude-plugin/plugin.json + marketplace.json
claude --plugin-dir .             # load this working copy as a plugin to try skills/agents
```

`marketplace.json` points at the GitHub URL (`source: url`), so users install whatever is on the default branch — not the local checkout.

## Layout and how the pieces connect

- `skills/<name>/SKILL.md` — 4 skills (`docs-management`, `mr-docs-sync`, `ticket-loop`, `tdd-workflow`). Installed with namespace `/san-workflow:<name>`.
- `agents/*.md` — 8 subagents. `ticket-loop` picks among them per ticket (planner → agents → architect pipeline), so agent `name`s are referenced by that skill.
- `rules/*.md` — global rules that the plugin system **cannot** install; users copy them into `~/.claude/rules/` and `@import` them from `~/.claude/CLAUDE.md`. `rules/workflow.md` is what triggers `docs-management` (commit-type → doc mapping); without it the skill doesn't auto-fire.
- `skills/docs-management/templates/` — frontmatter templates referenced via `${CLAUDE_SKILL_DIR}/templates/...`; keep that variable form rather than hard-coded paths.
- The `docs/` convention (`docs/feat/<slug>/`, `_general/`, `handoff/`, `changelog/<YYYY-MM>.md`, `TKT-NNN-*`, `ISS-YYYYMMDD-*`, 6-char-sha feature docs) is defined in `docs-management/SKILL.md` and consumed by `ticket-loop` and `mr-docs-sync`. Change naming rules in all three together. A target repo's `docs/docs-as-code.md` may override the baseline.

## Conventions when editing

- **Self-contained**: content is synced from the author's `~/.claude`. Do not reference skills, hooks, files, or archives that are not bundled in this repo (see commit `eff5910`, which stripped such cross-references).
- Agent frontmatter: `name`, `description`, `tools`, `model` (`inherit` by default; `architect`/`planner` use `opus`). Agents target Python projects (pytest, ruff, vulture, playwright-python).
- Language: `docs-management`, `mr-docs-sync`, rules, and README are Traditional Chinese with English technical terms; the other skills and agents are English. Match the file you're editing.
- When adding/removing a skill or agent, update the counts and lists in **all** of: `README.md` (tables + structure tree), `.claude-plugin/plugin.json` `description`, and `.claude-plugin/marketplace.json` plugin `description`. Bump `version` in `plugin.json` for releases.
- Commit messages: `<type>: <description>` with types `feat, fix, refactor, docs, test, chore, perf, ci` (from `rules/git-workflow.md`).
