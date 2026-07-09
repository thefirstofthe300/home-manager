---
name: flow-ship
description: Final phase of the flow pipeline — drafts a PR title/body from the task's state files and shows the commit list. Use standalone when the user wants to open a PR for the current branch, or as step 6 when invoked by the flow orchestrator. Always pauses for explicit approval before pushing or creating the PR — this is a hard checkpoint regardless of how the rest of the task was run.
---

# Flow: Ship

Turn an approved, validated, reviewed branch into a pull request. This is the one phase that
**always** stops and asks — pushing to a remote and opening a PR are shared-state, hard-to-
reverse actions that deserve an explicit go-ahead every time, with no exceptions for autonomous
runs.

## Step 1 — Gather context

Read whichever of these exist: `task.md`, `plan.md`, `validation.md`, `review.md`. Get the
commit list for this branch (`git log main..HEAD --oneline` or equivalent) and confirm the
working tree is clean (no uncommitted changes left over — if there are, that's a bug in an
earlier phase; surface it rather than silently including or discarding them).

## Step 2 — Check for a PR template

Look for `.github/PULL_REQUEST_TEMPLATE.md` or `.github/pull_request_template.md`. If present,
follow its structure. Otherwise use:

```markdown
## Summary
<1-3 bullets — what changed and why, drawn from task.md>

## Test plan
<what was validated — drawn from validation.md, as a checklist>
```

Keep it focused on outcome, not a step-by-step replay of the implementation process.

## Step 3 — Draft

Draft:
- **Branch**: confirm it matches the repo's naming convention (already set by `flow-intake`).
- **Title**: conventional-commit style if that's this repo's convention, otherwise a plain
  descriptive title. Include the Jira key if there is one.
- **Body**: from Step 2's template.
- **Base branch**: whatever `main`/`master`/`develop` this repo actually uses — confirm, don't
  assume.

## Step 4 — Checkpoint (hard stop)

Present the branch name, commit list, and full drafted PR title/body to the user. Ask
explicitly: "Ready to push and open this PR?" Wait for a clear yes. If they want changes to the
title/body, revise and re-confirm. Do not push or call `gh pr create` before this is answered —
this holds even when `flow-ship` was reached automatically via the `flow` orchestrator.

## Step 5 — Execute (only after approval)

```
git push -u origin <branch>
gh pr create --title "<title>" --body "<body>" --base <base>
```

Write `.claude/tasks/<slug>/pr.md` with the final title/body and the resulting PR URL.

## Step 6 — Wrap up

Report the PR URL to the user. If running as part of the `flow` pipeline, continue to
`flow-babysit` next. If invoked standalone, mention (don't invoke) that `flow-babysit` can watch
the PR through review and CI if they want that next. Don't touch the Jira ticket's status or add
a PR link to it automatically — if that seems useful, ask first, since it's a shared-state
mutation in another system.
