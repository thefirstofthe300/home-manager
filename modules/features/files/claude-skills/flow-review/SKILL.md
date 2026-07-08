---
name: flow-review
description: Fifth phase of the flow pipeline — runs multiple independent subagent review lenses (correctness, security, convention/simplicity, test coverage) over the full diff and consolidates ranked findings. Use standalone when the user wants a review of their current branch/diff before opening a PR, or as step 5 when invoked by the flow orchestrator. Ends with a checkpoint asking how to handle findings.
---

# Flow: Review

Get an honest second look at the diff before it becomes a PR — via independent subagents, not
your own read of every file (which would bloat context and carries your own implementation
bias anyway).

## Step 1 — Establish the diff scope

Determine the branch point (usually where this branch diverged from main/master) and get the
full diff range — but don't read the diff into your own context. Pass the range (e.g.
`git diff main...HEAD`) to each review subagent and let them pull it themselves.

## Step 2 — Spawn parallel review lenses

Spawn independent subagents (feature-dev's `code-reviewer` agent type if available and a good
fit, otherwise general-purpose with a focused prompt), each with a distinct lens:

1. **Correctness/bugs** — logic errors, edge cases, error handling gaps.
2. **Security** — injection, auth/permission issues, secrets, unsafe deserialization, etc.
   Scale scrutiny to what the diff actually touches (infra/auth-adjacent code gets more).
3. **Convention & simplicity** — does it match this repo's actual patterns (from `plan.md`'s
   discovered conventions), unnecessary complexity, dead code, over-abstraction.
4. **Test coverage** — are the changes actually covered by the validation harness, are there
   obvious untested edge cases.

Each subagent should return findings as a list: file:line, severity (high/medium/low),
description, suggested fix — not a narrative essay.

## Step 3 — Consolidate

Merge findings into `.claude/tasks/<slug>/review.md`, deduplicated, ranked by severity:

```markdown
# Review findings

## High
- `path:line` — <finding> — suggested fix: <...>

## Medium
- ...

## Low
- ...

## Resolutions
- <filled in after the checkpoint below>
```

## Step 4 — Checkpoint

Present only high and medium severity findings to the user (low-severity findings are noted in
the file but don't need to interrupt). Ask: fix now, fix later (leave as a follow-up / comment
on the ticket), or proceed as-is. Don't unilaterally decide this.

- If fixing now: delegate each fix through the same pattern as `flow-implement` (one subagent
  per fix, commit locally after), then re-run `flow-validate` if the fix touched code the
  harness covers.
- Record what was decided for each finding in the `## Resolutions` section of `review.md`.

## Step 5 — Report back

Short digest to the caller: count of findings by severity, what got fixed vs. deferred, path to
`review.md`.
