---
name: end-of-day-status
description: End-of-day sync — reviews today's work, posts Jira ticket updates, generates tomorrow's priority list, and sends it to Slack. Runs unattended with no approval prompts. Use this skill when the user asks what they got done today, wants to update their Jira tickets, needs a summary for tomorrow, wants to send a standup/EOD update, or says anything like "wrap up the day", "end of day", "what did I do today", "update my tickets", or "send my priorities to Slack". Trigger proactively any time the conversation has covered significant work and the user seems to be wrapping up.
---

# End-of-Day Sync

Automates the end-of-day workflow: review today's work → post Jira updates → summarize tomorrow → send to Slack.

**This skill runs unattended.** Never ask the user a question, never wait for confirmation, and never stop to present drafts. Make the call yourself and act. If a step fails, log the failure, skip that item, and keep going — one broken ticket must not block the standup. End with a short plain-text report of what was posted and what was skipped or failed.

## Step 1 — Gather today's work

Query the claude-mem-lite MCP server for all observations recorded today **across every project**, not just the current one.

Do not rely solely on the system-reminder timeline summary — always fetch fresh data from the MCP server.

### Primary path — direct search (always run this)

Call `mcp__plugin_claude-mem-lite_mem-lite__mem_search` with a broad query covering common work themes (e.g., "deployed committed PR fix feature") and a date-range filter for today (from the `currentDate` system context). Set `limit` to 25. If 25 results come back, paginate to catch the full day.

### Optional enhancement — timeline (run in parallel with the search above)

Call `mcp__plugin_claude-mem-lite_mem-lite__mem_timeline` anchored on today to catch anything the keyword search missed. Merge any additional observations into the results from the primary path.

### Enrichment

Once you have the combined list, load full details for observations that look relevant but are sparse using `mcp__plugin_claude-mem-lite_mem-lite__mem_get` with the relevant IDs.

Summarize what was actually completed today in plain terms — no implementation details, just outcomes (e.g., "Prometheus deployed to gremlin-ai, PR #1071 ready for review").

**Filter**: only include work that has an associated Jira ticket or open PR. Discard observations that are purely local/config work with no ticket and no PR — they don't belong in Jira comments or the standup. PRs in personal repos (`github.com/thefirstofthe300/*`) do not count — only PRs in work repos qualify.

## Step 2 — Pull open Jira tickets

Search for all tickets assigned to the current user that aren't done:

```
JQL: assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC
```

Use `mcp__plugin_hm_jira-mcp__jira_search_issues` (max 25). Then read full details for the tickets that are active or recently touched — skip anything stale (no updates in several weeks) unless it's obviously relevant to today's work.

## Step 3 — Check open PR statuses

Find all PRs referenced in today's observations or open Jira tickets. For each, fetch state, title, reviews, merged time, and URL with `mcp__plugin_hm_github__pull_request_read`. Fall back to `gh pr view <number> --repo <org/repo> --json state,title,reviews,mergedAt,url` only if the MCP call fails.

Run all lookups in parallel. Summarize results as a table:

| PR | Ticket | Status |
|----|--------|--------|
| #NNNN — title | EN-XXXXX | ✅ Merged / 🟡 Open, N reviews / 🔴 Closed |

Note which PRs have merged (relevant to Jira comment and transition drafts in the next step) and which are still open with or without reviews (feeds into tomorrow's priorities).

## Step 4 — Write Jira updates

For each ticket where today's work is relevant, write a single cohesive comment that synthesizes what was accomplished and the current PR state into one natural narrative — not two separate blocks. The PR status is context that shapes how you describe the work, not a separate item to append.

Good: "Completed the OpenTelemetry Operator and Collector deployment for gremlin-ai — operator uses cert-manager managed webhook TLS, collector runs as a DaemonSet with OTLP receivers and Kubernetes metadata enrichment. PR #1082 is open and awaiting first review."

Avoid: "Work done: deployed OTel Operator and Collector. PR status: #1082 open, no reviews."

Keep comments:
- **High-level**: outcomes and status, not implementation details
- **Brief**: 2–4 sentences max
- **Cohesive**: one narrative, not labelled sections

## Step 5 — Post comments and transitions

Post without asking.

**Avoid duplicates.** Before commenting on a ticket, read it with `mcp__plugin_hm_jira-mcp__jira_read_issue` and skip it if the current user already left a comment today. This makes a re-run safe.

Post each comment with `mcp__plugin_hm_jira-mcp__jira_add_comment`. Only comment on tickets that Step 1 tied to today's work — never comment on a ticket just because it is open.

**Transitions.** Apply a transition only when it is unambiguous:
- If every PR linked to the ticket has merged, call `mcp__plugin_hm_jira-mcp__jira_list_transitions` and apply the Done/Resolved transition with `mcp__plugin_hm_jira-mcp__jira_transition_issue`.
- If the ticket is in a not-started state (e.g., Backlog, To Do) but work happened today, transition it to the in-progress state.
- For anything else — stale-looking tickets, blocked or redundant tickets, a transition name that does not clearly match — leave the status alone and list the ticket under *Skipped* in the final report.

## Step 6 — Generate tomorrow's priorities

Based on current ticket and PR states, write a short priority list for tomorrow. Focus on:
- PRs awaiting first review or merge
- Blockers that need external coordination
- Next implementation steps for in-flight work
- Backlog items available if the above move fast

Keep it to 4–6 bullet points. Be specific about the action, not just the ticket name.

## Step 7 — Send to Slack

Send a standup-style summary to the user via Slack DM using `mcp__plugin_slack_slack__slack_send_message` with `channel_id: U03BZF4FQ0K`. Send it directly — do not save a draft.

If Step 1 found no ticket- or PR-linked work, skip the Slack message and say so in the final report rather than sending an empty standup.

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

If the Slack send fails (including because Slack isn't authenticated), do not retry in a loop and do not wait for the user. Print the full standup text in the final report along with the error so nothing is lost.

## Tone and style

- Fully autonomous — never pause for approval, never ask questions
- No implementation details in Jira comments (no namespace names, service URLs, config values, etc.)
- Be conservative with writes: only comment on tickets tied to today's work, and only transition when the rule in Step 5 clearly applies
