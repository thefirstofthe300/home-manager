# Core

Nix flake-based Home Manager config for 3 x86_64-linux hosts: `falcon` (personal), `beefcake` (work),
`iron-man` (personal). Runs on non-NixOS Linux (Fedora) via `nixGL`.

## Source map

- `flake.nix` — inputs + `homeConfigurations."dseymour@<host>"` outputs. nixpkgs overlay injects
  `flox` and `serena` packages (built from flake inputs, not nixpkgs).
- `modules/<host>/default.nix` — host-specific: imports a profile, sets feature flags, GPU/flatpak/dconf.
- `modules/profiles/{work,personal}.nix` — sets git identity (different emails), enables feature sets.
  `work.nix` enables cloud+development+sbom+kubernetes; `personal.nix` enables nothing itself (hosts
  layered on personal enable their own features).
- `modules/common/default.nix` — imports shared modules (ssh, packages, terminal, zsh, files, vim,
  direnv, secrets, user) + `../features`. Imported directly by every host's flake output alongside
  the host module.
- `modules/features/default.nix` — imports all feature modules; each is gated by its own
  `features.<name>.enable` (mkEnableOption/mkIf pattern).

Only `beefcake` currently has an actual `.sops.yaml` age key registered — see `mem:secrets`.

For MCP server / claude-code config specifics see `mem:mcp_servers`.
For commands/build validation see `mem:suggested_commands` and `mem:task_completion`.
For stack/version details see `mem:tech_stack`.
For code style see `mem:conventions`.
