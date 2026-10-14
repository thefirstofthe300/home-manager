---
name: writing
description: Write, edit, audit, and rewrite documentation, code comments, and prose so people can use it. Use when writing or editing a README, runbook, user guide, release notes, PR body, or any page someone reads to learn how something works; when asked to make docs clearer, tighten wordy writing, remove jargon, or check docs make sense to a newcomer; when asked to remove AI-isms or make text sound less like AI; and when asked to audit a diff, branch, file, or folder for over-commenting, bloated docs, or hard-to-read formatting (too many headings, bullets, bold, tables). Also use when the user says output is "too wordy", "noisy", or "hard to follow".
---

# Writing for the reader

Always-on standards live in two rules files, loaded every session:

- `~/.claude/rules/code-comments.md` for comments in code.
- `~/.claude/rules/writing-style.md` for documentation scope, formatting, and voice.

This skill adds the depth: how to write and edit docs well, how to audit work against
those rules, and how to strip AI patterns from prose. Pick the mode that fits the request.

## Mode 1: Write or edit documentation

Documentation fails in two directions. It assumes knowledge the reader does not have, or
it buries what they came for under things they did not ask about.

### Structure

Several small documents beat one large one. A reader arrives looking for one thing, and
pages let them find it and stop.

Define before you use. A term, a legend, or a cast of characters goes above the thing it
explains. When pages are ordered, order them so nothing is used as a proper noun before
the page that introduces it.

Cross-reference with links, never with bold text. Naming another document in bold tells
the reader it exists and leaves them to find it.

Every page needs a way out. If a page describes a failure, it says how to recover.

### Vocabulary

Name things for what they are, not for where they sit in a sequence. "Gate 2" tells a
reader nothing and is the first thing they forget. "Contract approval" names the artifact
in front of them.

Define every term the reader will meet elsewhere. If a word appears in a filename, a
field, a command, or the UI, it belongs in the document even if you prefer a different
word in prose. Name the internal term, say where it will turn up, and then keep using the
clearer word.

### Substance

Separate what the reader must do from what they can delegate. A troubleshooting or
procedure page should say, for each item, whether it is an operation someone can hand off
or a decision they own. Readers cannot infer this.

One coherent diagram beats several. If a flow has branches, put them in the flow and
label where each returns to. A branch that shows a failure and stops is a bug. Define
every element somewhere on the page, put legends above the diagram, and do not encode two
meanings in one line style.

### Working in a document someone else has touched

Check before you edit. Fetch the current content first, because someone may have edited
since you last saw it. Prefer targeted edits to replacing a whole page, and if you do
replace one, say so plainly.

Read the comments and address them. Reply saying what changed and why. Do not resolve
someone else's thread on their behalf.

Verify the write landed. Read back anything with structure, especially diagrams and
tables. A write that reports success is not evidence it rendered.

### Validate with a newcomer

Prose is hardest to judge when you already know what it means. Spawn a subagent briefed
as a competent engineer with no prior knowledge of the subject and no access to the
source, and have it read the pages in order. `references/newcomer-review.md` has a prompt
that works. Weight one finding above the rest: anything the reviewer actively misread,
even where they worked it out a paragraph later.

## Mode 2: Audit for bloat and formatting

Applies the rules to existing work and reports. It does not edit unless the user asks.

1. Pick the scope. Default is lines added on the current branch. If the user names files
   or a directory, audit those whole.
2. Run the scan. It lists candidates and per-file comment density; it does not judge.

   ```bash
   python3 -I ~/.claude/skills/writing/scripts/scan.py [--base REF] [PATH ...]
   ```

3. Judge each candidate against the surrounding code or text. The scan has false
   positives: "now" in a legitimate sentence, a why-comment that cites a ticket.
4. Read the in-scope files beyond what the scan flagged. The scan cannot see a comment
   that restates its code, a paragraph that answers no question, or a doc that repeats
   itself. Those are most of the real findings.
5. Check the rules' questions: for each comment, would deleting it cost a future reader
   anything? For each doc, does it need to exist or should it be a few lines in an
   existing one? For each section, what question does it answer? For each list, table,
   and heading, would prose be easier?
6. Report.

Leave alone: tool directives and markers (`nolint`, `eslint-disable`, `type: ignore`,
`noqa`, `shellcheck disable`, `+kubebuilder:`, `go:generate`, SPDX and license headers),
generated and vendored files, and doc comments a linter requires on exported symbols
(flag only if longer than needed). A long comment that explains a real why is not bloat;
suggest moving it to a doc instead of deleting it.

Report format: a one-line verdict with the finding count, then findings worst first, one
line each as `path:line  rule  fix`. The fix is concrete: "delete", "shorten to: <text>",
"merge into the section above", "replace table with a sentence". Group repeats ("12
comments in client.go restate the next line"). End by asking whether to apply them. If
the work is clean, say so in one line.

## Mode 3: Remove AI patterns from prose

For "remove AI-isms", "make this sound less like AI", or a prose audit for AI tells. Read
`references/ai-patterns.md` first. It holds the full pattern catalog, severity tiers
(P0 to P2), context profiles that set how strict to be, and the two output formats.

- `rewrite` (default): flag the patterns, return a cleaned version, summarize the
  changes, then run a second pass on the rewrite.
- `detect`: flag only, grouped by severity, with a note on which flags are judgment
  calls. Use when the user says "detect", "flag only", "audit only", or "scan", or when
  the text is someone else's.

Code comments and docs are the `docs` and `casual` profiles. Clarity matters more than
voice there, so apply the word tables loosely and the formatting rules strictly.

Modes combine. An audit of a branch usually runs Mode 2, and runs Mode 3 in `detect` on
any substantial prose it finds.
