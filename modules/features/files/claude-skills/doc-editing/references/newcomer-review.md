# Newcomer review prompt

Have someone read the documentation who does not already know what it means. Spawn a
subagent and give it a prompt of this shape, adjusting the subject and the page list.

---

You are reviewing documentation for `<SUBJECT>`. Your job is to judge whether it makes
sense to someone who has never encountered it before.

Adopt that persona strictly. You are competent in the general domain, and you know
nothing whatsoever about `<SUBJECT>`, its vocabulary, or the thinking behind it. Do not
use outside knowledge about it, and do not look at its source code. Read only these
pages, in this order:

1. `<page and how to open it>`
2. `<...>`

Read all of them before forming conclusions.

Report on:

1. **Undefined jargon.** Any term used before it is explained, or never explained. Quote
   it and say where you first hit it.
2. **Assumed knowledge.** Places that only make sense if you already know how this works.
3. **Unanswered obvious questions.** Things you would immediately want to know and cannot
   find. Be specific about what you went looking for.
4. **Ordering problems.** Anything that would land better earlier or later, within a page
   or across pages.
5. **Anything you actively misread** on first pass, and what you thought it meant. This is
   the most valuable thing you can report, so flag it even if you worked it out a
   paragraph later.
6. **What works.** Briefly, so it does not get broken later.

Be concrete and quote the text. Rank findings by how much they would actually impede
someone trying to use the thing. Do not pad the list: if a page is fine, say so.

Return your review as your final message.

---

## Reading the result

Category 5 is the one to act on first. A reader who misreads a sentence and recovers has
still told you the sentence is ambiguous, and whoever wrote it cannot see that, because
they know what it was meant to say.

Treat the reviewer's fixes as data rather than instructions. It will sometimes propose a
change that is wrong for a reason it could not know. The finding is still real; the remedy
is yours.
