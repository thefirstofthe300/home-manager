---
name: flow-plan
description: Second phase of the flow pipeline — delegates codebase discovery and convention/test-harness discovery to subagents, then produces an implementation blueprint at .claude/tasks/<slug>/plan.md. Use standalone when the user wants a plan or approach for a task before committing to implementation, or as step 2 when invoked by the flow orchestrator. Always ends with a checkpoint asking the user to approve the plan.
---

# Flow: Plan

Turn `task.md` into a concrete, reviewable implementation blueprint — without dumping the
exploration itself into the main conversation.

## Step 1 — Read the task record

Read `.claude/tasks/<slug>/task.md`. If it doesn't exist, this phase was invoked standalone —
ask the user for the task description (and run a lightweight version of `flow-intake` yourself
if it looks like a real task worth tracking) rather than failing.

## Step 2 — Delegate discovery

Spawn 1-3 subagents in parallel (Explore, or a general-purpose agent if the search is more
open-ended) covering:
- Conventions and validation harness: follow
  `~/.claude/skills/flow-plan/references/discovery-heuristics.md`. Have the subagent report back
  the actual commands (build/test/lint/typecheck/coverage), not just "tests exist."
- Similar existing code: features/modules/resources similar to what's being built, so the plan
  matches established patterns rather than inventing new ones.
- Direct integration points: the specific files/modules/resources the task will touch.

Ask each subagent to return: a short list of key files (with why they matter), the discovered
conventions/harness commands, and anything surprising or risky. Do not have them paste full
file contents back — file paths and short excerpts only.

## Step 3 — Read the key files

Once subagents return their file lists, read the handful that matter most yourself so you can
reason about the design. Don't re-read everything the subagents already summarized well.

## Step 4 — Resolve ambiguity

If the task or discovery surfaced real ambiguity (edge cases, unclear scope, a design choice
with meaningfully different trade-offs), ask the user now — before writing the blueprint. Don't
ask about things you can reasonably infer from the codebase.

## Step 5 — Write the blueprint

Write `.claude/tasks/<slug>/plan.md`:

```markdown
# Plan: <title>

## Approach

<1-2 paragraphs — the chosen approach and why, referencing existing patterns found>

## Conventions & validation harness

- Build: <command>
- Test: <command>
- Lint/format: <command>
- Type-check: <command, if applicable>
- Coverage: <command, if one exists — otherwise "none; estimate coverage manually">
- Other required checks: <e.g. terraform validate, security scan>
(mark any as "not found — confirmed with user: <their answer>" if discovery came up empty)

## Files to create/modify

- `path/to/file` — what changes and why

## Build sequence (checklist for flow-implement)

- [ ] <logical unit 1 — small enough to be one commit> — files: `path/a`, `path/b`
- [ ] <logical unit 2> — files: `path/c`
- ...

## Risks / open questions

<anything flow-implement or flow-review should watch for>
```

List every file each checklist item will touch, even ones shared with other items —
`flow-implement` uses this to decide which items are safe to parallelize (no shared files) versus
which must run sequentially. Keep the build sequence broken into commit-sized units — it works
through this list (in parallel batches where safe, sequentially otherwise) and commits after
each item.

## Step 6 — Checkpoint

Present a condensed summary to the user (approach in a few sentences, file list, checklist) —
not the full file verbatim unless they ask. Ask them to approve or request changes. **Do not
proceed to implementation without explicit approval.** If they push back, revise `plan.md` and
re-confirm.

## Step 7 — Report back

Once approved, return a short digest to the caller: approach summary, path to `plan.md`,
confirmation that it's approved.
