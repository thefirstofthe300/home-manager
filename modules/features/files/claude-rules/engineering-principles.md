# Engineering Principles

## Code Design

- **Push complexity into the abstraction, keep the implementation simple.** Callers get a clean, simple experience; the abstraction does the heavy lifting.
- **Functions do one thing with minimal side effects.** Trust your gut when something feels too big.
- **Dependencies earn their place.** The bar varies by language. A dependency must be actively maintained and solve a real problem that isn't worth owning.
- **Error posture matches context.** CLIs fail fast and loud. Long-running services degrade gracefully with logs, metrics, and traces that make debugging straightforward.
- **Interfaces emerge from working code.** Don't design APIs speculatively.

## Testing

- **Tests are both a safety net and a design tool.** They protect against regressions and shape how you think about the code.
- **Both unit and integration tests have a place.** Context determines the right balance — don't default to one style.
- **Cover what matters.** No numeric targets; coverage follows risk and criticality.
- **Tests are isolated.** Avoid shared state across tests. Each test cleans up after itself to prevent flakes.
- **Prototypes skip tests.** When exploring an idea, tests are overhead. They earn their place once the idea solidifies.

## Operational Thinking

- **Observability is first-class.** Logs, metrics, and traces are part of the feature, not an afterthought. Be deliberate, not verbose — capture critical behavior state in the form that makes most sense.
- **Feature flags for risky changes.** Especially rewrites that touch data, observability, or application state.
- **Design for failure upfront.** Always think through failure modes before shipping, not after an incident forces it.
- **Operational docs ship with the feature.** Written for an ops person: what they need to deploy, configure, and run it successfully.
- **Alerts are actionable. Errors are debuggable.** A bad error message is as bad as no error message. An absent error message is a critical bug.

## Change Management

- **One logical change per commit, squash on merge.** Granular commits during development; clean history at the PR level.
- **PRs stay focused.** A PR becomes too big when it sprawls across unrelated files or concerns. Only change what the task requires.
- **APIs are stable once merged.** Backwards compatibility is maintained. Get the interface right before merging — it rarely changes after.
- **Rollback-safe by default.** Design changes to be safely reversible unless there is an explicit, accepted reason not to.
- **Staging is mandatory.** Always deploy to staging before production.

## Simplicity

- **Delete aggressively.** Every line of code needs a well-understood reason to exist. If it serves no purpose or can be simplified without loss, remove or simplify it.
- **Dependencies need strong justification.** Only add one if it meaningfully simplifies a significant portion of code and is actively maintained.
- **Refactoring is separate from feature work.** Never mix refactor commits with feature commits. When you spot a refactoring opportunity, flag it and ask — do not act on it unilaterally.
- **Incremental improvement over rewrite.** Always prefer improving what exists over starting fresh.
- **Before writing code, stop at the first rung of this ladder that holds:**
  1. Does this need to exist at all? Speculative need → skip it. (YAGNI)
  2. Does the stdlib do it? Use it.
  3. Does a native platform feature cover it? (`<input type="date">` over a picker lib, CSS over JS, DB constraint over app code.) Use it.
  4. Does an already-installed dependency solve it? Use it. Never add a new one for what a few lines can do.
  5. Can it be one line? Make it one line.
  6. Only then: write the minimum code that works.
