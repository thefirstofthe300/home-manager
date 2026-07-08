---
name: flow-implement
description: Third phase of the flow pipeline — works through the plan's checklist one logical unit at a time via subagents, committing locally after each. Use standalone to resume implementation on a task that already has an approved plan, or as step 3 when invoked by the flow orchestrator.
---

# Flow: Implement

Execute an approved plan without doing the editing yourself — each checklist item gets its own
subagent so your own context only accumulates short results, not diffs.

## Step 1 — Read state

Read `.claude/tasks/<slug>/plan.md` (must exist and be approved — if it doesn't exist, tell the
user to run `flow-plan` first) and `.claude/tasks/<slug>/progress.md` if present (tracks what's
already done, for resuming).

If `progress.md` doesn't exist yet, create it with the plan's checklist copied in, all unchecked.

## Step 2 — Work the checklist

For each unchecked item, in order (respect obvious dependencies — e.g. don't implement a
consumer before the thing it depends on):

1. Spawn a subagent scoped to just this item. Give it: the specific checklist line, the
   relevant file list/conventions from `plan.md`, and instruction to make the change following
   the repo's existing style. Do **not** give it the whole plan file dump if it's long — extract
   what's relevant to this item.
2. Tell the subagent to report back: files changed, a one-line description of what it did, and
   whether it hit anything unexpected (missing dependency, plan assumption that turned out
   wrong, etc.) — not a full diff.
3. If the subagent flags a plan assumption as wrong, stop and re-evaluate: either the fix is
   small enough to proceed with a note, or it needs to go back through `flow-plan`. Use
   judgment; ask the user if it's a real fork in the road.
4. Commit the change locally:
   - Determine the commit convention: check the repo's own git log for its existing style; if
     none is evident, use Conventional Commits (matches your default).
   - One logical change per commit — if the subagent's work naturally splits into more than one
     commit-worthy piece, commit them separately.
   - This workflow auto-commits locally without pausing for approval (per your standing
     decision for `flow`) — but still show the commit message in the transcript as it happens,
     so there's a visible trail.
5. Mark the item checked in `progress.md`, and append a line noting the commit hash + one-line
   summary.

## Step 3 — Handle failures

If a subagent can't complete an item (genuinely blocked, not just needs another attempt), retry
once with more context. If it's still blocked, mark it blocked in `progress.md` with why, and
surface it to the user rather than skipping silently or guessing around it.

## Step 4 — Report back

Once all items are checked (or you've surfaced a blocker), return a short digest: how many
items completed, commit count, any blockers, path to `progress.md`. Don't restate every commit
message individually unless asked — the log is in git and in `progress.md`.
