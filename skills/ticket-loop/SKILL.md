---
name: ticket-loop
description: Batch-execute unfinished tickets using a planner → agents → architect pipeline. Use when the user wants to process backlog tickets, complete remaining tickets, loop through open tickets, finish pending work, or references unfinished ticket-tracked work.
---

# Ticket Loop

Scan `docs/` for unfinished tickets, plan execution, delegate to agents, and verify with architect review. Designed for batch-processing multiple tickets in a single session.

## Prerequisites

- Tickets follow `docs-management` conventions (see `skills/docs-management/SKILL.md`)

## Workflow

### Phase 1: Discovery

Find all actionable tickets using the Grep tool:

```
pattern: "status: (backlog|in-progress)"
glob: "TKT-*.md"
path: <scope_path or "docs/feat/">
```

For each ticket found, read the file and extract:
- `id`, `status`, `priority`, `feature`, `depends-on`, `blocks`
- Objective and Acceptance Criteria

**Filtering rules:**
- Include: `status: backlog` and `status: in-progress`
- Exclude: `status: done`, `cancelled`, `blocked` (unless the blocker is in the current batch)
- Exclude: `assignee: human` — only process tickets with `assignee: claude` or unset
- If a blocked ticket's blocker is in the current batch, treat the blocker as a dependency (execute it first); after the blocker completes, change the blocked ticket to `status: in-progress`
- If a ticket's `depends-on` references a ticket outside the scoped directory, check the blocker's status. If not `done`, exclude the ticket and report it as unresolvable in Phase 6
- If a scope path is given (e.g., `docs/feat/agent-python-migration/`), limit to that directory
- Sort by priority (P0 first), then by dependency order (`depends-on` before `blocks`)

Present the ticket list to the user for confirmation before proceeding. Example:

```
Found 3 actionable tickets:
1. TKT-010 (P2, backlog) — refactor-cleaner Python migration
2. TKT-011 (P2, backlog) — doc-updater Python migration
3. TKT-012 (P1, backlog) — e2e-runner Python migration [depends-on: TKT-010]

Proceed with all 3?
```

### Phase 2: Planning

Spawn a **planner agent** with this prompt structure:

```
Read the following tickets and create a consolidated execution plan:

[For each ticket: file path + full content]

Requirements:
- Group related tickets that can share context
- Identify which agent type best handles each ticket
- Flag dependency chains that constrain execution order
- For each ticket, list the specific files to modify and the nature of changes
- Output a step-by-step plan with clear agent assignments
```

The planner reads the ticket files and referenced source files to produce a concrete plan. Review the plan for completeness — every Acceptance Criteria item should map to at least one plan step.

If a ticket lacks a `Technical Approach` section, the planner must draft one based on the Objective and Acceptance Criteria. Flag these tickets in the plan output.

### Phase 3: Architect Pre-Review (skip for single-ticket batches)

Before execution, spawn an **architect agent** to review the plan:

```
Review this execution plan for [N] tickets:

[Plan from Phase 2]

Check for:
- Technical errors or contradictions in proposed changes
- Missing edge cases not covered by the plan
- Consistency with existing codebase patterns
- Dependencies or ordering issues

Provide specific corrections, not general observations.
```

Incorporate architect feedback into the plan before proceeding. If feedback is substantial, re-run the planner with the corrections.

### Phase 4: Execution

Execute the plan. Choose the execution strategy based on ticket dependencies:

**Independent tickets** — execute sequentially via separate agent calls. No shared state between them; each agent receives only its own ticket context:
- Each agent receives its specific portion of the plan
- Include full context: ticket content, files to modify, expected changes
- Agents write edits directly (not in worktrees — worktree edits have proven unreliable)

**Dependent tickets** — execute sequentially in dependency order.

**Agent selection** — match ticket content to the appropriate agent type:

| Ticket involves | Agent type |
|----------------|------------|
| Code refactoring, dead code removal | `refactor-cleaner` |
| Documentation updates, codemaps | `doc-updater` |
| Test creation or migration | `tdd-guide` or `e2e-runner` |
| Code quality, linting fixes, review | `code-reviewer` |
| Security changes | `security-reviewer` |
| Architecture decisions | `architect` |
| General code changes | `general-purpose` |

If no specialized agent fits, execute the edits directly without delegation.

After each agent completes, verify its output against the ticket's Acceptance Criteria.

**If verification fails:**
1. Attempt one self-correction pass — re-read the ticket AC, identify the gap, fix it
2. If still failing, mark the ticket `status: blocked` with a Progress Log entry explaining the failure, and continue to the next ticket
3. Report all blocked tickets in Phase 6

### Phase 5: Architect Post-Review

After all tickets are executed, spawn an **architect agent** for holistic review:

```
Review the changes made across [N] tickets:

[List of all modified files with summary of changes]

Original ticket objectives:
[Ticket IDs and objectives]

Check for:
- Cross-file consistency (naming, patterns, conventions)
- Regressions or contradictions between ticket changes
- Completeness — are all Acceptance Criteria met?
- Residual artifacts from pre-change state (e.g., stale references)

Provide specific file:line findings, not general observations.
```

Apply any corrections the architect identifies.

### Phase 6: Finalization

1. **Update ticket statuses** — set each completed ticket to `status: done` and append a dated Progress Log entry with a one-line summary of what was done
2. **Verify** — grep for any remaining `status: backlog` or `status: in-progress` in the scoped directory to confirm all tickets are resolved
3. **Report** — summarize what was done:
   - Number of tickets completed
   - Files modified
   - Any tickets that could not be completed (and why)

Do not commit automatically — wait for the user to request a commit.

## Important Constraints

- **No worktree isolation.** Agent edits in git worktrees silently fail to persist. Always edit in the main working directory.
- **Read before edit.** Every file must be read before modification. Agents that skip this step will hit Edit tool errors.
- **User confirmation gates.** Always confirm the ticket list (Phase 1) and the plan (Phase 2) with the user before executing. The architect reviews (Phases 3 and 5) do not require user confirmation — apply corrections directly.
