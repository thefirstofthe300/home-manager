# Writing Style

## Write the smallest document that answers the reader's question, in plain prose

This covers files Claude writes (READMEs, runbooks, design notes, PR bodies, commit
bodies) and any prose in code. Chat replies are covered by `communication.md`; comments
by `code-comments.md`. To write, edit, audit, or de-AI a document in depth, use the
`writing` skill.

## Scope

- Do not create a new doc file unless asked. Update the existing one.
- Do not write summary, changelog, or "what I did" markdown files after finishing work.
  Report in chat instead.
- Do not document what the code already shows (function lists, parameter tables,
  directory trees). It goes stale and adds nothing.
- Each paragraph must answer a question a reader would actually have. If you cannot
  name the question, cut it.
- Give one example, not three. Add more only when they show genuinely different cases.
- Start with what the reader needs to do or know. Background, history, and rationale
  come after, and only where skipping them would lead the reader astray.
- Never use a real person's name in an example or runbook. Use a role.

## Formatting

Default to short paragraphs of prose. Reach for structure only when the content has it.

- Bullets: only for parallel, list-like items. One level deep, never nested.
  Steps in order get a numbered list.
- Headings: only when a doc runs past roughly one screen or has three or more
  distinct sections. No headings on a short note. Sentence case, and no generic ones
  like "Overview" or "Summary".
- Bold: almost never. If something must stand out, rewrite the sentence to lead
  with it. Do not start every bullet with a bold label.
- Tables: only for comparing three or more items across three or more attributes.
  Two columns is a list.
- Code blocks: only for text the reader will copy or run. Use inline code for names.
- No emoji, horizontal rules, blockquote callouts (`> Note`), or ASCII banners.
- Link to other documents. Do not name them in bold.

## Voice

- No em dashes, and no `--` standing in for one. Use a comma, colon, parentheses, or
  a full stop.
- Vary sentence length. Several short declaratives in a row read as a list of
  assertions. Lead with the "because" rather than stating two facts and leaving the
  reader to join them.
- Use one name per concept. Do not rotate synonyms for variety.
- Say "is" and "has", not "serves as", "boasts", or "features". Say "use", not
  "leverage" or "utilize".
- Cut intensifiers and filler ("it's worth noting", "importantly", "robust",
  "seamless"), significance inflation, and chatbot phrasing ("Great question!",
  "I hope this helps"). State the fact.
- Name things for what they are, not for their place in a sequence ("contract approval",
  not "Gate 2").
- Capitalize product and tool names. Reread your own edits for half-rewritten
  sentences and typos.

## Length check before finishing

Reread the draft and delete anything the reader could skip without losing the
answer. If a section restates the one before it, remove one. A short doc that is
complete beats a long one that is thorough.

If the user explicitly asks for a long or exhaustive document, write it, but the
formatting and voice rules still apply.
