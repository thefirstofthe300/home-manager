# Tech Stack

- Nix flake, Home Manager (nix-community, follows nixpkgs-unstable). `stateVersion = "24.05"` fixed
  across all hosts — do not bump without understanding HM state-version migration implications.
- Flake inputs beyond nixpkgs/home-manager: `nixgl` (GPU support on non-NixOS), `nix-flatpak`,
  `sops-nix` (secrets), `flox`, `serena` — the latter two are consumed via a nixpkgs overlay in
  `flake.nix`, not as separate HM modules.
- Secrets: sops-nix + age, see `mem:secrets`.
- No test suite / CI / linter in this repo. `nix flake check`/`home-manager switch` are the only
  validation available.
- claude-code is itself managed as a home-manager program (`programs.claude-code` in
  `modules/features/development.nix`), including its MCP server set, plugins, and permission settings.
