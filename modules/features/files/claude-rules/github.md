# GitHub Usage

## Use the GitHub MCP server as the primary way of interacting with GitHub

When the `github` MCP server is connected, use its tools (`mcp__github__*`) as the
default way to interact with GitHub — issues, pull requests, reviews, checks,
repository content, etc. Only fall back to the `gh` CLI when the MCP server cannot
perform the required task.

**Steps:**
1. Prefer the GitHub MCP server's tools for any GitHub operation.
2. Fall back to the `gh` CLI only when the MCP server is incapable of the task at
   hand. The reason it's incapable doesn't matter — a missing tool, a connection
   failure, a scope limitation, or anything else all count the same: fall back.
3. Don't reach for `gh` first "just in case" or out of habit — always try the MCP
   server's capability first for a given task.

**Why:** Keeping GitHub MCP as the primary path keeps interactions consistent and
auditable through the MCP server. The CLI is a fallback of last resort, not an
equal alternative.
