# Discovering project conventions and validation harnesses

Shared reference for `flow-plan`, `flow-validate`, and `flow-implement`'s test writer. Check
sources in this order and stop as soon as you have a confident answer — don't run every
heuristic every time.

## 1. Explicit documentation (always check first)

- `CLAUDE.md` (repo root and any nested ones near the code you're touching)
- `README.md` / `CONTRIBUTING.md`
- `.github/CONTRIBUTING.md`, `docs/development.md` or similar

Look specifically for: build command, test command, lint/format command, type-check command,
required pre-commit steps, and any stated coding conventions (naming, error handling, test
style, commit message format).

## 2. Ecosystem signal files (fall back to this if step 1 is silent)

Look for the file(s) present and infer the relevant commands:

| Signal file | Ecosystem | Likely commands |
|---|---|---|
| `package.json` | Node/JS/TS | `npm test` / `pnpm test` / `yarn test`, check `scripts` block for `lint`, `build`, `typecheck` |
| `pyproject.toml`, `setup.cfg`, `tox.ini` | Python | `pytest`, `ruff check`, `mypy`, `tox` |
| `Cargo.toml` | Rust | `cargo test`, `cargo clippy`, `cargo fmt --check` |
| `go.mod` | Go | `go test ./...`, `go vet ./...`, `golangci-lint run` |
| `*.tf` / `terraform/` | Terraform | `terraform validate`, `terraform fmt -check`, `tflint`, `checkov`/`tfsec` |
| `Makefile` | any | `make test`, `make lint`, `make build` — read the targets, don't assume names |
| `justfile` | any | `just test`, `just check` — read the recipes |
| `Taskfile.yml` | any | `task test` |
| `build.gradle`, `pom.xml` | Java/Kotlin | `./gradlew test`, `mvn test` |
| `flake.nix` / `*.nix` (this kind of repo) | Nix/Home Manager | usually no test suite — validate via `home-manager switch --flake .#<target>` or `nix flake check` |

## 3. Coverage tooling (used by flow-implement's test writer)

Check step 1's explicit docs first, same as above. If silent, infer from the ecosystem:

| Ecosystem | Likely coverage command |
|---|---|
| Node/JS/TS | `jest --coverage`, `vitest run --coverage`, or `nyc`/`c8` wrapping the test command |
| Python | `pytest --cov`, `coverage run -m pytest && coverage report` |
| Rust | `cargo tarpaulin`, `cargo llvm-cov` |
| Go | `go test ./... -cover`, `go tool cover -func=coverage.out` |
| Java/Kotlin | JaCoCo via `./gradlew jacocoTestReport` or `mvn jacoco:report` |
| Terraform/infra config | no meaningful line coverage concept — rely on `terraform validate`/`plan` review and estimate qualitatively instead |

If none of these are wired up in the repo, don't add a coverage tool just to satisfy this —
that's a bigger change than a single task warrants. Estimate coverage by reasoning through
which branches/paths the new tests exercise instead, and say plainly that it's an estimate.

## 4. CI configuration (most reliable ground truth if present)

`.github/workflows/*.yml`, `.circleci/config.yml`, `.gitlab-ci.yml`, etc. — whatever commands CI
actually runs are the real validation harness, even if they diverge from what a README claims.
Prefer this over guessing from signal files alone when both are present.

## 5. Still nothing found

If none of the above yields a usable build/test/lint command, do not guess or invent one. Ask
the user directly: name the repo, what you checked, and ask what command(s) validate a change
here. Record their answer in `plan.md` so later phases (and future runs) don't have to ask
again.

Once you have the answer, also ask whether they want it documented in the repo itself, not just
in `plan.md` — this is a one-time cost that saves every future run (and every other person or
agent) from hitting the same gap. Be intelligent about where it belongs, don't just default to
one file:

- If a root (or nested, near the relevant code) `CLAUDE.md` already exists, offer to append the
  command(s) there under a fitting existing section (or a new "Commands"/"Testing" section if
  none fits) — this repo already treats CLAUDE.md as the source of truth for agent-facing
  conventions, so keep it consistent.
- If there's no `CLAUDE.md` but a `README.md`/`CONTRIBUTING.md` has a Development/Testing/
  Contributing section, offer to add it there instead.
- If neither exists, ask whether they want a minimal `CLAUDE.md` created for this — prefer that
  over README, since README usually targets human onboarding rather than agent conventions.

Only write to the repo's docs after they say yes — this is a real content change to their
project, not scratch state.
