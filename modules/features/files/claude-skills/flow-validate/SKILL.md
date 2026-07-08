---
name: flow-validate
description: Fourth phase of the flow pipeline — runs the repo's discovered build/test/lint harness in a subagent and iterates on failures within a bounded retry budget. Use standalone any time to (re)run checks on the current working tree ("run the tests", "validate this", "does this pass CI checks"), or as step 4 when invoked by the flow orchestrator.
---

# Flow: Validate

Run the real validation harness for this repo and drive it to green, without flooding your own
context with raw test/build output.

## Step 1 — Determine the harness

If `.claude/tasks/<slug>/plan.md` exists and records validation commands, use those. Otherwise
(standalone invocation, or plan didn't capture it), discover it yourself following
`~/.claude/skills/flow-plan/references/discovery-heuristics.md`.

If discovery still comes up empty, ask the user directly what validates a change in this repo —
don't guess and don't skip validation silently.

## Step 2 — Delegate the run

Spawn a subagent to:
1. Run the discovered commands (build, lint, type-check, tests — whatever applies).
2. If everything passes, report a short pass summary (which checks ran, that they passed) —
   not the full output.
3. If something fails, the subagent should attempt to fix it itself (read the failure, make a
   targeted fix, rerun) up to **3 rounds**. Commit each successful fix locally with a message
   describing what was wrong (e.g. `fix: correct off-by-one in pagination test`), same commit
   conventions as `flow-implement`.
4. After 3 rounds, if still failing, stop and report back: which check(s) still fail, a
   condensed excerpt of the actual error (not the whole log), and what was already tried.

## Step 3 — Write the report

Write `.claude/tasks/<slug>/validation.md`:

```markdown
# Validation report

## Checks run

- [x] Build — pass
- [x] Lint — pass
- [ ] Tests — 2 failing (see below)

## Fixes applied this run

- <commit hash> — <what was wrong, what was fixed>

## Unresolved (if any)

- <check> — <condensed error> — <what was tried>
```

## Step 4 — Report back / checkpoint

- If everything passed (possibly after fixes): short digest to the caller, no user interruption
  needed as part of the `flow` pipeline.
- If unresolved failures remain after the retry budget: stop and present the unresolved items to
  the user, with your best read of what's going on. Ask how they want to proceed (keep trying,
  they'll take a look themselves, or it's expected/out of scope for now).
