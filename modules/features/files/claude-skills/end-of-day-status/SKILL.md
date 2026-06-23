---
name: end-of-day-status
description: End-of-day sync — reviews today's work, drafts Jira ticket updates for review, generates tomorrow's priority list, and sends it to Slack. Use this skill when the user asks what they got done today, wants to update their Jira tickets, needs a summary for tomorrow, wants to send a standup/EOD update, or says anything like "wrap up the day", "end of day", "what did I do today", "update my tickets", or "send my priorities to Slack". Trigger proactively any time the conversation has covered significant work and the user seems to be wrapping up.
---

# End-of-Day Sync

Automates the end-of-day workflow: review today's work → draft Jira updates → get approval → post → summarize tomorrow → send to Slack.

## Step 1 — Gather today's work

Query the claude-mem MCP server for all observations recorded today **across every project**, not just the current one.

Do not rely solely on the system-reminder timeline summary — always fetch fresh data from the MCP server.

### Primary path — direct search (always run this)

Call `mcp__plugin_claude-mem_mcp-search__search` with `dateStart` set to today's date (from the `currentDate` system context) and a broad query covering common work themes (e.g., "deployed committed PR fix feature"). Set `limit` to 25 and `orderBy` to `date_asc`. If 25 results come back, paginate with `offset: 25` to catch the full day.

### Optional enhancement — corpora (run in parallel with the search above)

Call `mcp__plugin_claude-mem_mcp-search__list_corpora`. If it returns any corpora, call `mcp__plugin_claude-mem_mcp-search__timeline` for each one in parallel, filtering to today. Merge any additional observations into the results from the primary path. If `list_corpora` returns an empty array, skip this step — corpora are an optional named-index layer on top of the raw observation store; their absence does not mean observations are missing.

### Enrichment

Once you have the combined list, load full details for observations that look relevant but are sparse using `mcp__plugin_claude-mem_mcp-search__get_observations` with the relevant IDs.

Summarize what was actually completed today in plain terms — no implementation details, just outcomes (e.g., "Prometheus deployed to gremlin-ai, PR #1071 ready for review").

**Filter**: only include work that has an associated Jira ticket or open PR. Discard observations that are purely local/config work with no ticket and no PR — they don't belong in Jira comments or the standup. PRs in personal repos (`github.com/thefirstofthe300/*`) do not count — only PRs in work repos qualify.

## Step 2 — Pull open Jira tickets

Search for all tickets assigned to the current user that aren't done:

```
JQL: assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC
```

Use `mcp__plugin_claude-code-home-manager_jira-mcp__jira_search_issues` (max 25). Then read full details for the tickets that are active or recently touched — skip anything stale (no updates in several weeks) unless it's obviously relevant to today's work.

## Step 3 — Check open PR statuses

Find all PRs referenced in today's observations or open Jira tickets. For each, run:

```
gh pr view <number> --repo <org/repo> --json state,title,reviews,mergedAt,url
```

Run all lookups in parallel. Summarize results as a table:

| PR | Ticket | Status |
|----|--------|--------|
| #NNNN — title | EN-XXXXX | ✅ Merged / 🟡 Open, N reviews / 🔴 Closed |

Note which PRs have merged (relevant to Jira comment and transition drafts in the next step) and which are still open with or without reviews (feeds into tomorrow's priorities).

## Step 4 — Draft Jira updates

For each ticket where today's work is relevant, draft a single cohesive comment that synthesizes what was accomplished and the current PR state into one natural narrative — not two separate blocks. The PR status is context that shapes how you describe the work, not a separate item to append.

Good: "Completed the OpenTelemetry Operator and Collector deployment for gremlin-ai — operator uses cert-manager managed webhook TLS, collector runs as a DaemonSet with OTLP receivers and Kubernetes metadata enrichment. PR #1082 is open and awaiting first review."

Avoid: "Work done: deployed OTel Operator and Collector. PR status: #1082 open, no reviews."

Keep comments:
- **High-level**: outcomes and status, not implementation details
- **Brief**: 2–4 sentences max
- **Cohesive**: one narrative, not labelled sections

Also flag any tickets where the **status looks stale or wrong**. For tickets whose PR merged, include that in the comment and propose transitioning the ticket to Done.

Present all drafts to the user before posting anything. Format like:

---
**EN-XXXXX** — [Ticket title]
> [Draft comment text]

---

Ask: "Ready to post these, or any changes?" Do not post until the user confirms.

## Step 5 — Post approved comments

Once the user approves, post each comment using `mcp__plugin_claude-code-home-manager_jira-mcp__jira_add_comment`.

Then address any stale status flags: for each one, use `mcp__plugin_claude-code-home-manager_jira-mcp__jira_list_transitions` to see available transitions, propose the right one, and ask for confirmation before applying it via `mcp__plugin_claude-code-home-manager_jira-mcp__jira_transition_issue`.

## Step 6 — Generate tomorrow's priorities

Based on current ticket and PR states, write a short priority list for tomorrow. Focus on:
- PRs awaiting first review or merge
- Blockers that need external coordination
- Next implementation steps for in-flight work
- Backlog items available if the above move fast

Keep it to 4–6 bullet points. Be specific about the action, not just the ticket name.

## Step 7 — Send to Slack

Send a standup-style summary to the user via Slack DM using `mcp__plugin_claude_ai_Slack__slack_send_message` with `channel_id: U03BZF4FQ0K`.

Format the message as a classic standup update with three sections:

```
*Yesterday*
• <one bullet per meaningful outcome — what shipped, what moved forward>

*Today*
• <one bullet per tomorrow's priority from Step 6>

*Blockers*
• <any blockers, or "None" if clear>
```

Rules for standup format:
- Each bullet is one sentence, action-oriented, past tense for yesterday and future tense for today
- Reference ticket numbers and PR numbers as Slack hyperlinks: `<URL|display text>` (e.g., `<https://gremlininc.atlassian.net/browse/EN-4321|EN-4321>` and `<https://github.com/Gremlin-Ltd/gremlin/pull/1082|#1082>`). Use the actual URLs from the Jira and GitHub data already fetched in earlier steps — never construct URLs from memory.
- Skip the PR status table — the standup bullets should subsume that information
- Keep the whole message under 15 lines; if there's more to say, trim ruthlessly
- Use Slack `*bold*` for section headers, plain `-` or `•` for bullets

If Slack isn't authenticated, prompt the user to authenticate and wait for confirmation before proceeding.

## Tone and style

- Conversational at review steps — always pause and wait for user approval before posting or making transitions
- Autonomous for read-only steps — don't ask permission to read tickets or observations
- No implementation details in Jira comments (no namespace names, service URLs, config values, etc.)
- Status transitions are low-risk but still confirm before applying
