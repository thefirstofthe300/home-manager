# Claude Memory (claude-mem) Usage

## Always query claude-mem before exploring the codebase

When answering exploratory questions about the codebase, architecture, past decisions,
or ongoing work, **always query the claude-mem MCP server first** before doing fresh
filesystem searches or reads.

**Steps:**
1. Use `mem-search` or `get_observations` to retrieve relevant prior context.
2. Use that context to answer directly, or to narrow what needs verification.
3. Only fall back to fresh filesystem exploration when memory is absent or clearly stale.

**Why:** claude-mem accumulates observations across sessions. Skipping it means
re-discovering things that are already known, wasting tool calls and context window.

**When to still verify:** Memory records can become stale. If a memory names a specific
file, function, or resource, confirm it still exists before acting on it. Trust current
filesystem state over a stale memory when they conflict — and update or remove the
stale memory.
