# Git Rules

## Branches
Always create a new branch for a new feature or bugfix that includes a Jira ticket
in the branch name. If you are unclear about what ticket the work is associated with, 
prompt the user to provide it.

Example:

```
<Jira_ticket>/<description>
```

## Committing Changes

Before creating a commit, show the proposed commit message and wait. The user may request changes before committing — never commit automatically during this review cycle. Only run `git commit` when the user explicitly says to proceed.

Never push to GitHub (`git push`) or create a pull request unless the user explicitly asks for it.

## Commit Messages
All commits must follow the Conventional Commits v1.0.0 specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:** `feat`, `fix`, `build`, `chore`, `ci`, `docs`, `style`, `refactor`, `perf`, `test`

**Rules:**
- Description is required, imperative mood, lowercase, no trailing period
- Scope is optional: `feat(auth): add login endpoint`
- Breaking changes: append `!` before the colon (`feat!:`) and/or add a `BREAKING CHANGE:` footer
- Body and footers are separated from the preceding section by a blank line
