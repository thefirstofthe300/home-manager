# Code Comments

## Default to no comment; write one only when the code cannot say it

Names, types, and structure carry the "what". A comment earns its place by
recording something a reader cannot recover from the code itself.

Write a comment for:
- Why something is done a surprising way (workaround, hidden constraint, ordering
  dependency, performance trade-off).
- An invariant or assumption the code relies on but does not enforce.
- A pointer to the ticket, issue, or spec that explains a quirk.

Do not write a comment that:
- Restates the code (`// increment counter`, `# loop over items`).
- Narrates the change: "added", "now", "no longer", "previously", "fixed",
  "refactored", "updated to". Comments describe the code as it is; history lives in git.
- Cites the current task or ticket for ordinary code. That belongs in the commit.
- Labels sections with banners or dividers (`// ---- helpers ----`).
- Preserves commented-out code. Delete it.
- Leaves a `TODO` with no owner or ticket.

Length: One line is the default. Three lines is the ceiling. If it needs more,
restructure the code so it explains itself, or move the explanation to a doc and link it.

Doc comments (godoc, docstrings, JSDoc) go on public API only. Open with one
sentence saying what it does. Do not repeat parameter names or types already in the
signature, and skip `Args:` / `Returns:` sections unless a linter or the language
convention requires them, then keep each entry to a few words.

When editing existing code:
- Match the surrounding comment density. A sparse file stays sparse.
- Do not add comments to lines you did not change.
- Keep tool directives untouched (`nolint`, `eslint-disable`, `# type: ignore`,
  `shellcheck disable`, `+kubebuilder:` markers, license headers).
