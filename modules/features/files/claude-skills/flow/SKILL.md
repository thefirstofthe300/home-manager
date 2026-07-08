---
name: flow
description: Orchestrates a task from a Jira issue or freeform prompt all the way through planning, implementation, validation, review, and into a pull request. Use when the user wants to "take this ticket to a PR", "build this end to end", "work this issue", "ship this feature", or gives a task and clearly wants the full lifecycle handled, not just one step. Delegates each phase to a dedicated flow-* skill and to subagents — keeps the main conversation free of raw exploration output, diffs, and logs.
---

# Flow — end-to-end task orchestration

You are the orchestrator. Your job is sequencing and context discipline, not doing the work
yourself. Every phase below is its own skill (`flow-intake`, `flow-plan`, `flow-implement`,
`flow-validate`, `flow-review`, `flow-ship`) and can also be invoked standalone. When running
the full pipeline, invoke them in order via the Skill tool.

This works across any repository type (Terraform, Python, Java, Go, Rust, infra config, etc.).
Nothing here is language-specific — every phase discovers conventions from the target repo
rather than assuming any.

## Context discipline (read this first, it's the whole point)

- State for the current task lives at `.claude/tasks/<slug>/` inside the repo being worked on.
  Each phase skill writes one short markdown file there (`task.md`, `plan.md`, `progress.md`,
  `validation.md`, `review.md`, `pr.md`). These files are already condensed — you may read them
  directly.
- You must **never** pull raw subagent transcripts, full diffs, full test/build logs, or full
  file contents into your own context. That work happens inside subagents (via the `Agent`
  tool) or scripted checks; only a short digest (pass/fail, file list, one-line summary) comes
  back to you. If a subagent's summary is vague, ask it a follow-up rather than re-deriving the
  detail yourself.
- If you catch yourself about to `Read` a large log, diff, or exploration result directly —
  stop, and instead spawn or re-prompt a subagent to summarize it for you.

## Determining the slug and state directory

1. If the task has a Jira key (e.g. `PROJ-123`), the slug is the key, lowercased (`proj-123`).
2. Otherwise, derive a short kebab-case slug from the task description (3-6 words, e.g.
   `add-login-endpoint`).
3. State directory: `.claude/tasks/<slug>/` at the repo root.

## Resuming

Before starting, check whether `.claude/tasks/<slug>/` already exists.
- If it does, read the digest files present and figure out the last completed phase (e.g.
  `plan.md` exists but `progress.md` doesn't → plan is done, implementation hasn't started).
  Summarize the resume point to the user in one or two sentences and continue from there —
  don't restart earlier phases or re-ask questions already answered in `task.md`/`plan.md`.
- If it doesn't exist, this is a fresh task — start at `flow-intake`.

## Pipeline

Invoke each phase with the Skill tool, passing the slug/state directory along. Read that
phase's digest file when it returns, relay a short status update to the user, then move on.

1. **`flow-intake`** — resolves the task source, creates the branch, writes `task.md`.
2. **`flow-plan`** — discovers conventions/test harness, writes `plan.md`.
   **Hard checkpoint**: present the plan digest and wait for explicit approval or edits before
   continuing. Do not proceed to implementation without it.
3. **`flow-implement`** — works the plan's checklist, commits locally as it goes, writes/updates
   `progress.md`. No pause between commits — local commits during this workflow don't require
   per-commit approval, but every commit message is still shown in the transcript for
   visibility.
4. **`flow-validate`** — runs the discovered validation harness, writes `validation.md`. Only
   pauses if it exhausts its retry budget with unresolved failures — otherwise continues
   silently as part of the pipeline.
5. **`flow-review`** — parallel review lenses over the full diff, writes `review.md`.
   **Checkpoint**: present ranked findings and ask fix-now / fix-later / proceed. If fixing,
   loop back through `flow-implement` for the fix and `flow-validate` to confirm, then return
   here.
6. **`flow-ship`** — drafts the PR title/body and shows the commit list.
   **Hard checkpoint, no exceptions**: always ask for explicit go-ahead before this skill
   pushes the branch or opens the PR, regardless of how autonomous the rest of the run was.

## After the PR is open

`flow-ship` stops once the PR exists. Mention to the user that the `babysit` skill can monitor
the PR through review/CI if they want that next — don't invoke it automatically.

## Errors and blockers

If any phase gets genuinely stuck (can't find a validation harness, ambiguous requirements,
merge conflicts, repeated validation failures), stop and ask the user rather than guessing or
skipping the phase. Record the blocker in the relevant state file so the resume logic above
picks it up correctly next time.
