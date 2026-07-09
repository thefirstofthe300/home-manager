---
name: flow-babysit
description: Seventh phase of the flow pipeline — watches the PR opened by flow-ship until CI passes and all review comments/threads are resolved, delegating fixes to subagents and pushing follow-up commits. Use standalone to babysit any open PR ("keep an eye on this PR", "babysit PR #123"), or as the final step when invoked by the flow orchestrator.
---

# Flow: Babysit

Stay with the PR after `flow-ship` opens it until it's actually mergeable — checks green, review
decision acceptable, no unresolved threads or actionable comments left. Follows the same
conventions as the rest of the pipeline: state lives in `.claude/tasks/<slug>/`, real work
(reading CI logs, diagnosing failures, fixing issues) happens in subagents, and you only ever
hold short digests.

This phase doesn't busy-poll within a single turn. Each invocation does one check-and-act pass,
then either reports done or schedules a wakeup to check again later — matching how this harness
actually handles "wait and check back."

## Step 1 — Read state

Read `.claude/tasks/<slug>/pr.md` (written by `flow-ship`) for the PR number/URL, and
`.claude/tasks/<slug>/babysit.md` if present (tracks prior rounds, for resuming). If invoked
standalone with no task directory, resolve the PR from the current branch (`gh pr view`) or ask
which PR to watch.

If `babysit.md` doesn't exist yet, create it with an empty round log.

## Step 2 — Check current status

Delegate to a subagent (this keeps raw CI logs and long comment threads out of your context):

```bash
gh pr view <number> --json \
  number,state,isDraft,mergeable,mergeStateStatus,reviewDecision,headRefOid,statusCheckRollup,url
```

For unresolved review threads, resolve the repo first, then page through GraphQL:

```bash
repo_json=$(gh repo view --json owner,name)
owner=$(jq -r '.owner.login // .owner.name' <<<"$repo_json")
repo=$(jq -r '.name' <<<"$repo_json")

thread_query='query($owner:String!,$repo:String!,$number:Int!,$cursor:String){repository(owner:$owner,name:$repo){pullRequest(number:$number){reviewThreads(first:100,after:$cursor){pageInfo{hasNextPage endCursor}nodes{id,isResolved,isOutdated,path,line,comments(last:1){nodes{author{login},body,createdAt,url}}}}}}}'
cursor_args=()
while :; do
  page=$(gh api graphql -f query="$thread_query" -f owner="$owner" -f repo="$repo" -F number=<number> "${cursor_args[@]}")
  printf '%s\n' "$page" | jq -r '.data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved==false)
    | [.id,.path,(.line//""),(.isOutdated|tostring),(.comments.nodes[-1].author.login//""),(.comments.nodes[-1].body|gsub("\n";" ")|.[0:240])]
    | @tsv'
  jq -e '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage' >/dev/null <<<"$page" || break
  cursor=$(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor' <<<"$page")
  cursor_args=(-f cursor="$cursor")
done
```

Have the subagent report back only: check pass/fail/pending counts and names of any failing
checks, review decision, count and one-line summary of each unresolved thread/new actionable
comment. Not full logs, not full comment bodies.

## Step 3 — Act on what's found

- **CI failing**: spawn a fix subagent per distinct failure (same pattern as `flow-implement`) —
  give it the failing check name and a condensed error summary, not the full log. After a fix,
  run the relevant command from `plan.md`'s validation harness locally before pushing.
- **Unresolved review thread or new actionable comment**: spawn a fix subagent per item. Treat
  bot summaries as useful signal but verify the actual finding against the code before acting —
  don't fix phantom issues. Only resolve the thread afterward, once you've verified the fix
  addresses it (via the `resolveReviewThread` GraphQL mutation) — never resolve preemptively.
- **Running fixes concurrently**: a CI failure and a review comment can easily point at the same
  file. Before spawning fix subagents in parallel, check what each targets — only ones with no
  file overlap may run concurrently; anything sharing a file runs sequentially, one committed
  before the next starts. When unsure whether two fixes overlap, treat them as overlapping.
- **CI still pending, nothing actionable yet**: don't wait synchronously. Skip to Step 5.
- Commit fixes and push directly to the existing branch — this is a continuation of the push
  already approved when `flow-ship` opened the PR, not a new remote action, so it doesn't need a
  fresh approval each round. Never force-push; only append commits.
- Append a round entry to `.claude/tasks/<slug>/babysit.md`: timestamp, what was checked, what
  was found, what was fixed, commit hash(es).

## Step 4 — Stop condition

Stop only when, on a fresh check: all checks are passing (or intentionally skipped), the review
decision is acceptable (approved, or no review required by this repo's process), no unresolved
review threads remain, no new actionable comments are unaddressed, and local `git status` is
clean. Do one fresh sweep (repeat Step 2) before declaring done — don't trust a stale read.

## Step 5 — Report or reschedule

- **Done**: report to the user with concrete evidence — latest commit SHA, check results,
  review decision, thread count (should be zero). This is the end of the `flow` pipeline.
- **Not done, nothing actionable right now** (e.g. CI still running): report the current state
  briefly and schedule a wakeup to re-run this check — 60-90s for typical CI, longer if this
  repo's checks are known to take longer. Don't schedule an aggressive short-interval poll.
- **Not done, blocked** (e.g. a review comment needs a decision only the user can make, or a
  fix attempt failed twice): stop and ask, same as any other phase — don't keep looping on
  something that needs human input.
