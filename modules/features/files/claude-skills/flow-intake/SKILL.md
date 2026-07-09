---
name: flow-intake
description: First phase of the flow pipeline — resolves a task from a Jira issue key/URL, a freeform prompt, or a newly-created Jira ticket (added to the current sprint and assigned to the current user by default), creates the working branch, and writes the task digest to .claude/tasks/<slug>/task.md. Use standalone when the user wants to just "start" or "kick off" a ticket/task without running the rest of the pipeline yet, or as step 1 when invoked by the flow orchestrator.
---

# Flow: Intake

Turn a Jira issue or a freeform description into a well-defined task record and a branch to
work on. This phase is cheap enough to do directly — you generally don't need a subagent here,
just the jira-mcp tools and a few git/file operations.

## Step 1 — Identify the source

- If the user gave a Jira key (e.g. `PROJ-123`) or a Jira URL, that's the source.
- If the user's prompt *mentions* something that sounds like it should have a ticket but didn't
  give a key, ask them for it before proceeding — don't guess a key.
- If the user gave a freeform description with no ticket, check whether this repo actually
  needs one before asking:
  - Look at the repo's CLAUDE.md/README and any project memory for an explicit statement that
    Jira tickets aren't required (e.g. a personal-project convention).
  - If nothing says tickets are optional, ask the user: provide an existing ticket key, have
    one created now (see Step 2a), or confirm explicitly that this is a no-ticket task.
  - If the repo convention says tickets aren't needed, proceed without one.

## Step 2 — Fetch the ticket (if there is one)

Use the jira-mcp MCP tools:
- `jira_read_issue` for a known key.
- `jira_search_issues` if you only have a loose reference and need to find the right issue.

Pull: key, title, description/acceptance criteria, issue type, labels/components, and any
linked issues worth knowing about. Discard fields that don't help implementation (watchers,
avatars, custom workflow metadata, etc.) — this file should stay short.

If jira-mcp isn't connected or the call fails, tell the user and ask whether to proceed without
ticket details (freeform) or wait/retry.

## Step 2a — Create a new ticket (if the user asked for one)

When the user wants a new Jira ticket created for this task rather than using an existing one:

1. Determine the project/board it belongs to (ask if it's not obvious from context).
2. Create the issue via `jira_create_issue` (or the `acli` skill), using the task description
   as the summary/description.
3. Unless the user says otherwise, apply these defaults:
   - **Assignee**: the currently authenticated user — don't leave it unassigned.
   - **Sprint**: the current active sprint for that board, not the backlog. Look it up with
     `jira_get_active_sprint` (or `acli jira board list-sprints` / `acli jira sprint view`), then
     set it via `jira_set_issue_sprint` (or `acli jira workitem edit`) if creation doesn't accept
     sprint directly.
   - If there's no active sprint (sprints aren't in use on this board, or nothing is currently
     active), say so and ask rather than silently leaving it in the backlog or guessing.
4. Treat the newly created ticket as the source for the rest of this skill — continue at Step 2
   to fetch and record it in `task.md` like any other ticket.

These are defaults, not hard rules — an explicit assignee, sprint, or "leave it unassigned"/
"put it in the backlog" from the user overrides them.

## Step 3 — Determine the slug

- Ticket-backed task: slug = ticket key, lowercased (`proj-123`).
- No ticket: derive a 3-6 word kebab-case slug from the description (e.g.
  `add-login-endpoint`).

## Step 4 — Set up the branch

Check the repo's own conventions first (CLAUDE.md, existing branch names via `git branch -a` /
`git log --all --oneline -20` for a pattern). Absent a repo-specific convention, default to
`<Jira_ticket>/<short-description>`, or `<type>/<slug>` (conventional-commit type prefix) when
there's no ticket.

```
git checkout -b <branch-name>
```

Only create the branch if not already on it (resuming an in-progress task should reuse the
existing branch — check `task.md` first if the state directory already exists).

## Step 5 — Write the task record

Ensure `.claude/tasks/` is gitignored in this repo (add an entry if missing — this is a local
scratch dir, not something to commit).

Write `.claude/tasks/<slug>/task.md`:

```markdown
# <title>

**Source:** <Jira KEY (link) | ad-hoc>
**Branch:** <branch-name>
**Type:** <feat|fix|chore|... — your best read of the work type>

## Description / acceptance criteria

<condensed — the essential ask, not the full ticket dump>

## Notes

<anything else genuinely load-bearing: linked issues, constraints the user mentioned, explicit
non-goals>
```

## Step 6 — Report back

Return a short digest to whoever invoked you (the user, or the `flow` orchestrator): title,
branch name, ticket link if any, one-line summary, and the path to `task.md`. Do not paste the
full ticket description back into the conversation — it's already in the file.
