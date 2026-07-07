# Serena Usage

## Use Serena when a repository has it configured

In repositories that have a Serena MCP server configured, use Serena's symbol-aware
tools (`find_symbol`, `get_symbols_overview`, `find_referencing_symbols`,
`replace_symbol_body`, etc.) instead of generic Read/Grep/Edit whenever they fit the
task at hand.

**Steps:**
1. Check whether a `serena` MCP server is connected for the current repository.
2. If it is, call `initial_instructions` before starting a coding task, then prefer
   Serena's symbolic tools for locating and editing code.
3. Fall back to Read/Grep/Edit when Serena isn't configured for the repository, or
   the task isn't code search/editing (e.g. git history, docs, config file contents).

**Why:** Serena's symbol-aware search and edits are more precise and token-efficient
than plain-text tools for codebases it understands.
