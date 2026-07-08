# Serena Usage

## Use Serena only when the repository has been onboarded

The Serena MCP server may be connected globally, but only rely on its symbol-aware
tools (`find_symbol`, `get_symbols_overview`, `find_referencing_symbols`,
`replace_symbol_body`, etc.) in repositories that have already been **onboarded** with
Serena — i.e. a `.serena/` directory with project config/memories exists at the repo
root. Otherwise, use the normal tools (Read/Grep/Edit/Glob) instead.

**Steps:**
1. Check whether the current repository has a `.serena/` directory before reaching
   for Serena's tools.
2. If it's onboarded, call `initial_instructions` before starting a coding task, then
   prefer Serena's symbolic tools for locating and editing code.
3. If it's not onboarded (or the `serena` MCP server isn't connected at all, or the
   task isn't code search/editing — e.g. git history, docs, config file contents),
   fall back to Read/Grep/Edit/Glob. Don't trigger onboarding automatically; if
   Serena would clearly help in an un-onboarded repo, ask the user before running it.

**Why:** Onboarding builds project-specific symbol indexes and memories. Without them,
Serena's tools lose the precision/token advantage over plain-text search and can
return noisy or incomplete results.
