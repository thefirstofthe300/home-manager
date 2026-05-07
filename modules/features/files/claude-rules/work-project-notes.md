# Work Project Notes

When you finish a work task or project, create a note in Nextcloud to capture it
for future self-evaluations and resume writing.

## When to trigger

Create a note when:
- A PR is merged or a feature ships
- A significant bug or incident is resolved
- A design, architecture, or technical decision is finalized
- A project milestone or deliverable is complete
- The user says something like "that's done", "ship it", "wrap this up", etc.

Do not create a note for routine chores (dependency bumps, typo fixes, minor config
changes) unless the user asks.

## Workstream

The workstream is a controlled vocabulary. Allowed values:

- Platform Engineering
- Developer Experience
- Security & Compliance
- Data & Analytics
- Reliability & On-Call
- Product Features

**Matching rules:**
1. Infer the workstream from context (the project, codebase, PR, etc.).
2. Pick the closest match from the list above. Fuzzy matching is fine —
   "infra work" → Platform Engineering, "on-call" → Reliability & On-Call.
3. If nothing fits well, ask: "Which workstream should I file this under?
   Current options: [list]. Or tell me a new one to add."
4. If the user specifies a new workstream, add it to the allowed values list
   in this rule file (`claude-rules/work-project-notes.md`) before creating
   the note, so future projects can match against it.

Use the workstream as the folder name in Nextcloud Notes. The path for the note
should be: `<Workstream>/<YYYY-MM-DD> <project title>.md`

## How to create the note

Use the Nextcloud MCP server to create the file. Check what tools are available
(create_note, create_file, files_put, or similar) and use whichever fits.

## Note format

Write the note in plain Markdown. Use this structure:

```markdown
# <Project Title>

**Date:** YYYY-MM-DD  
**Workstream:** <workstream>  
**Scope:** <one sentence — what this was and why it mattered>

## What I did

<2–4 bullet points. Each bullet is one concrete action you took.
Active voice, past tense. Name the specific system, tool, or codebase.>

## Outcome

<1–3 bullet points. Measurable results where possible: latency reduced by X%,
error rate dropped from Y to Z, shipped to N users, unblocked team, etc.
If no metric is available, describe the qualitative change.>

## Skills & technologies

<Comma-separated list: Go, Kubernetes, incident response, cross-team
coordination, etc. Include both technical and non-technical skills.>

## Resume bullet (draft)

<One sentence in resume style: strong verb + what you did + quantified result.
Example: "Reduced p99 API latency by 40% by replacing synchronous DB calls
with a batched async pipeline.">
```

## Guidelines

- Be specific and factual. Avoid vague praise ("improved the system greatly").
- Quantify everything you can. If you don't have a number, say so and leave a
  TODO for the user to fill in later.
- The resume bullet should be ready to paste into a CV with minimal editing.
- Keep the full note under one screen of text — if it runs longer, split into
  multiple bullets under "What I did".
- After creating the note, tell the user the path where it was saved.
