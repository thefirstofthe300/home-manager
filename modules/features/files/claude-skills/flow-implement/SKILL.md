---
name: flow-implement
description: Third phase of the flow pipeline — works through the plan's checklist one logical unit at a time via subagents, writing tests for new code by default, committing locally after each. Use standalone to resume implementation on a task that already has an approved plan, or as step 3 when invoked by the flow orchestrator.
---

# Flow: Implement

Execute an approved plan without doing the editing yourself — each checklist item gets its own
subagent so your own context only accumulates short results, not diffs.

Tests are part of "done," not an afterthought: unless the task explicitly says not to write
tests, every checklist item gets a second, independent subagent whose only job is testing the
first one's work.

## Step 1 — Read state

Read `.claude/tasks/<slug>/plan.md` (must exist and be approved — if it doesn't exist, tell the
user to run `flow-plan` first) and `.claude/tasks/<slug>/progress.md` if present (tracks what's
already done, for resuming).

If `progress.md` doesn't exist yet, create it with the plan's checklist copied in, all unchecked.

## Step 2 — Decide the testing policy once, up front

Before working the checklist, determine whether tests are in scope for this task:

- Check `task.md` and however this skill was invoked for an explicit instruction not to write
  tests (e.g. "no tests", "skip tests", "just the prototype").
- If there's no such instruction, tests are the default — every item that adds or changes
  behavior gets tests. Record the policy at the top of `progress.md` so resuming later doesn't
  re-ask ("Testing: on" or "Testing: off — user said <reason>").
- A checklist item can still turn out to be untestable on its own merits (pure config, docs,
  generated code, a one-line constant change) — that's a per-item judgment call by the test
  subagent in step 3.4 below, not a reason to skip the policy entirely.

## Step 3 — Work the checklist

For each unchecked item, in order (respect obvious dependencies — e.g. don't implement a
consumer before the thing it depends on):

1. Spawn a coder subagent scoped to just this item. Give it: the specific checklist line, the
   relevant file list/conventions from `plan.md`, and instruction to make the change following
   the repo's existing style. Do **not** give it the whole plan file dump if it's long — extract
   what's relevant to this item. Its job is the implementation only — it does not write tests
   for its own work.
2. Tell the coder subagent to report back: files changed, a one-line description of what it did,
   and whether it hit anything unexpected (missing dependency, plan assumption that turned out
   wrong, etc.) — not a full diff.
3. If the coder subagent flags a plan assumption as wrong, stop and re-evaluate: either the fix
   is small enough to proceed with a note, or it needs to go back through `flow-plan`. Use
   judgment; ask the user if it's a real fork in the road.
4. If the testing policy is on, spawn a second, independent subagent — the test writer — once
   the coder subagent's change looks solid:
   - Give it the coder's file list and one-line description (not the whole plan), plus the
     test framework/conventions recorded in `plan.md` (or discovered fresh if this item touches
     an area `flow-plan` didn't cover).
   - Its job is testing the change the coder just made, up to roughly 80% coverage of the
     **new/changed code for this item** — not the whole file, and not padding line count to hit
     a number. Meaningful edge cases and error paths matter more than the percentage.
   - If a coverage tool exists in this repo (check `plan.md`, or the coverage tooling reference
     in `~/.claude/skills/flow-plan/references/discovery-heuristics.md`), have it run the tool
     and report the actual percentage for the changed lines. If there's no coverage tool
     available, have it estimate instead — reason through which branches/paths the new tests
     exercise and report an honest estimate (e.g. "no coverage tool in this repo — new tests
     exercise the success path and both error branches, roughly 75-80%").
   - If the test subagent finds the change genuinely untestable as written (pure config/docs/
     generated code, or the coder's implementation needs restructuring to be testable), it
     should say so rather than writing hollow tests or reaching into the implementation itself
     — surface that back to you, and decide whether to send it back to the coder subagent for a
     small rework or accept it as untested with a documented reason.
5. Commit the change locally:
   - Implementation and its tests land as one commit per checklist item (the coder's change and
     the test writer's tests together) — that's the unit of "done" for this item. If the
     subagents' work naturally splits into more than one commit-worthy piece, commit those
     separately.
   - Determine the commit convention: check the repo's own git log for its existing style; if
     none is evident, use Conventional Commits.
   - This workflow auto-commits locally without pausing for approval — but still show the
     commit message in the transcript as it happens, so there's a visible trail.
6. Mark the item checked in `progress.md`, and append a line noting the commit hash, a one-line
   summary, and the test outcome (e.g. "tested, ~85% coverage (pytest --cov)", "tested, estimated
   ~75% (no coverage tool)", or "untested — <reason>").

## Step 4 — Handle failures

If a subagent (coder or test writer) can't complete an item (genuinely blocked, not just needs
another attempt), retry once with more context. If it's still blocked, mark it blocked in
`progress.md` with why, and surface it to the user rather than skipping silently or guessing
around it.

## Step 5 — Report back

Once all items are checked (or you've surfaced a blocker), return a short digest: how many
items completed, commit count, test coverage summary (e.g. "tested" vs "untested" counts, and
whether coverage was measured or estimated), any blockers, path to `progress.md`. Don't restate
every commit message individually unless asked — the log is in git and in `progress.md`.
