# Discovering project conventions and validation harnesses

Shared reference for `flow-plan` and `flow-validate`. Check sources in this order and stop as
soon as you have a confident answer — don't run every heuristic every time.

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

## 3. CI configuration (most reliable ground truth if present)

`.github/workflows/*.yml`, `.circleci/config.yml`, `.gitlab-ci.yml`, etc. — whatever commands CI
actually runs are the real validation harness, even if they diverge from what a README claims.
Prefer this over guessing from signal files alone when both are present.

## 4. Still nothing found

If none of the above yields a usable build/test/lint command, do not guess or invent one. Ask
the user directly: name the repo, what you checked, and ask what command(s) validate a change
here. Record their answer in `plan.md` so later phases (and future runs) don't have to ask
again.
