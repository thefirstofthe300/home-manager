# Jira Ticket Updates

At meaningful progress points during work, prompt the user about posting an
update to the associated Jira ticket.

## When to prompt

Prompt after:
- A PR is opened or merged
- A design or architectural decision is made
- A significant blocker is identified or resolved
- A milestone or deliverable is complete
- A long-running task has new status worth sharing

Do not prompt for every small change. Use judgment — if the update would be
noise on the ticket, skip it.

## Decision flow

1. **Ticket is known** (mentioned in the branch name, conversation, or previous
   context): Ask "Want me to post an update to <TICKET-ID>?"

2. **No ticket mentioned**: Ask "Is there a Jira ticket for this? If so, what's
   the ID and I'll post an update."

3. **User says no ticket exists**: Ask "Should I create one? I can open a ticket
   in the right project if you give me the project key."

4. **User declines at any step**: Drop it and move on without asking again for
   the same task.

## Posting the update

Use the Atlassian MCP server to add a comment to the ticket. The comment should be
a concise status update suitable for stakeholders:

```
*Status update — <YYYY-MM-DD>*

*What happened:* <1–2 sentences: the concrete thing that was done or decided>

*Next:* <what comes next, or "complete" if done>

*Blockers:* <any blockers, or omit if none>
```

Keep it under 100 words. No implementation details unless directly relevant to
stakeholders. Use Jira's wiki markup (not Markdown) if the MCP server requires it.

## Creating a ticket

If the user wants a new ticket created, ask for:
- Project key (e.g. ENG, PLAT, SEC) if not obvious from context
- Brief title for the issue

Then create it as a Story or Task (whichever fits) with a short description
summarizing what was built or decided. Report the new ticket ID to the user.
