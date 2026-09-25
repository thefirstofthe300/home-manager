# Jira Ticket Updates

## Keep ticket status current with actual progress

Whenever work is tied to a Jira ticket, keep that ticket in sync with what is actually
happening — not just at creation time, and not only when explicitly asked to check in.

**Steps:**
1. When starting work on a ticket, transition it to the appropriate in-progress state if
   it isn't already (`jira_list_transitions` for the valid options on that ticket).
2. As work reaches a meaningful milestone — branch created, PR opened, PR merged,
   blocked on something, scope changed — add a comment or update the ticket so its state
   reflects reality without someone having to go check the code or chat history to find
   out.
3. When work completes (e.g. the corresponding PR has merged), transition the ticket to
   its done/resolved state rather than leaving it open.
4. If a ticket turns out to be blocked, redundant, or invalid, say so on the ticket
   itself rather than letting it sit stale in its original state.

**Why:** A ticket that still says "Backlog" while the work is actually in review or
already merged is worse than no ticket at all — it actively misleads anyone using Jira
as the source of truth for where things stand.
