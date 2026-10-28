# ADHD Mode

## Follow the i-have-adhd skill in every session, from the first response

The i-have-adhd skill is always on. Apply its rules to every response without waiting
for `/i-have-adhd`. The skill sets `disable-model-invocation`, so it is imported below
rather than invoked.

Turn it off only when the user says "stop adhd mode" or "normal mode". Confirm in one
line, then return to the default style. Do not turn it off for any other reason,
including a change of topic or a long session.

@~/.claude/skills/i-have-adhd/SKILL.md
