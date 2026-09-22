---
name: doc-editing
description: Write and edit documentation for people who have to use it. Use this skill when writing a user guide, a README, a runbook, release notes, or any page someone will read to learn how something works, and when editing or reviewing existing documentation. Also use it when asked to make docs clearer, tighten wordy writing, remove jargon, or check whether docs make sense to a newcomer.
---

# Writing documentation people can use

Documentation fails in two directions. It assumes knowledge the reader does not have, or it buries what they came for under things they did not ask about. Most of what follows is aimed at one of those.

## Structure

**Several small documents beat one large one.** A reader arrives looking for one thing. Pages let them find it and stop; a single long document makes them scroll past everything else first.

**Define before you use.** A term, a legend, a color key, or a cast of characters all belong above the thing they explain, not below it. When pages are ordered, order them so nothing is used as a proper noun before the page that introduces it.

**Cross-reference with links, never with bold text.** Naming another document in bold tells the reader it exists and leaves them to find it.

**Every page needs a way out.** If a page describes a failure, it says how to recover. A dead end sends the reader back to guessing, which is the state the document was supposed to end.

## Voice

**No em dashes.** Few people use them, and they make prose read as machine-written. Commas, colons, parentheses, or a full stop all do the job.

**Vary the sentences.** Short declaratives in a row read as a list of assertions rather than an argument. Mix dependent clauses, compound sentences, and the occasional short one where the point deserves a hard stop. Subordination usually beats two sentences: lead with the "because" rather than stating two facts and leaving the reader to join them.

**Cut anything the reader does not need.** Design rationale, history, and the reasoning behind a decision are interesting to whoever built the thing and are noise to whoever is using it. Keep the reasoning only where a reader who does not know it would do the wrong thing.

**Capitalize proper names.** Product and tool names are names.

**Edit for grammar, punctuation, and spelling.** Check your own edits as carefully as anyone else's, and watch for half-rewritten sentences where an earlier phrasing is still clinging on.

## Vocabulary

**Name things for what they are, not for where they sit in a sequence.** "Gate 2" tells a reader nothing and is the first thing they forget. "Contract approval" names the artifact in front of them, so someone asked to approve a contract already knows what they are looking at.

**Define every term the reader will meet elsewhere.** If a word appears in a filename, a field, a command, or the UI, it belongs in the document even if you prefer a different word in prose. Naming the internal term, saying where it will turn up, and then declining to use it is better than pretending it does not exist.

**Never use a real person's name.** An example naming a colleague reads as a requirement to involve them. Use a role or a placeholder.

## Substance

**Separate what the reader must do from what they can delegate.** Any troubleshooting or procedure page should say, for each item, whether it is an operation someone can hand off or a decision they own. Readers cannot infer this, and getting it wrong wastes their time in both directions.

**Diagrams: one coherent picture beats several.** If a flow has branches, put the branches in the flow and label each one with where it returns to. Splitting the exceptions into a second diagram forces the reader to hold two pictures at once.

- Every element in a diagram gets defined somewhere on the page, including files and abbreviations.
- Legends go above the diagram.
- A branch that shows a failure and stops is a bug. Show the way out.
- Do not encode two different meanings in one line style. If dotted means both "loops back" and "is now invalid," nobody can read it.

## Working in a document someone else has touched

**Check before you edit.** Fetch the current content first. Someone may have edited since you last saw it, and a wholesale rewrite silently discards their work. Prefer targeted edits to replacing a whole page, and if you do replace one, say so plainly so they know to check.

**Read the comments and address them.** Reply saying what changed and why. Do not resolve someone else's thread on their behalf; leave that to them.

**Verify the write landed.** Read back anything with structure to it, especially diagrams, tables, and anything where whitespace is meaningful. Formats silently mangle content, and a write that reports success is not evidence it rendered.

## Validating it

Prose is hardest to judge when you already know what it means. The fix is to have someone read it who does not.

Spawn a subagent briefed as a competent engineer with no prior knowledge of the subject and no access to the source, and have it read the pages in order. `references/newcomer-review.md` has a prompt that works.

Weight one finding above the rest: **anything the reviewer actively misread**, even where they worked it out a paragraph later. Those are invisible to anyone close to the work, and they are the ones worth fixing.
