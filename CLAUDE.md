# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Nix flake-based Home Manager configuration managing three x86_64-linux hosts: **falcon** (personal), **beefcake** (work), and **iron-man** (personal). Runs on non-NixOS Linux (Fedora) using `nixGL` for GPU/OpenGL support.

## Commands

```bash
# Apply configuration for the current host
home-manager switch --flake .#dseymour@<hostname>

# e.g.
home-manager switch --flake .#dseymour@beefcake

# Update flake inputs
nix flake update
```

There is no test suite, CI, or linter configured. Validate changes by running `home-manager switch`.

## Architecture

### Module Hierarchy

```
flake.nix
  └─ modules/<host>/default.nix     # Host-specific: packages, GPU, flatpaks
       └─ modules/profiles/<work|personal>.nix  # Profile: enables features, sets git identity
            └─ modules/common/default.nix       # Shared: shell, terminal, ssh, vim, direnv
                 └─ modules/features/            # Opt-in tool groups
```

All hosts import their host module + `modules/common` + `nix-flatpak`. Host modules import a profile. Common imports all features (but features are gated behind options).

### Feature Module Pattern

Every feature module under `modules/features/` follows this pattern:

```nix
{ lib, pkgs, config, ... }:
{
  options.features.<feature>.enable = lib.mkEnableOption "<description>";
  config = lib.mkIf config.features.<feature>.enable {
    home.packages = with pkgs; [ ... ];
  };
}
```

Features are toggled on by profiles (`modules/profiles/work.nix` enables all four; `personal.nix` enables none) or by individual hosts (`falcon` enables all four on top of personal profile; `iron-man` enables `development` only).

Current features: `kubernetes`, `cloud`, `development`, `sbom`, `local-llm`, `vllm`.

### Host Differences

- **beefcake** (work): All features enabled, NVIDIA GPU with CUDA, `targets.genericLinux.gpu`, nix GC, Slack/Fastmail flatpaks, vllm
- **falcon** (personal): All four features enabled, krew for kubectl plugins, Riot flatpak
- **iron-man** (personal): `development` feature only, GNOME dconf theme settings

### Flake Inputs

- `nixpkgs` (unstable), `home-manager`, `nixGL` (GPU on non-NixOS), `nix-flatpak`

## Conventions

- **Adding a new tool/package**: If it's broadly useful, add to `modules/common/packages.nix`. If it belongs to a feature domain, add to the appropriate `modules/features/*.nix`. If host-specific, add to `modules/<host>/default.nix`.
- **Adding a new feature module**: Create `modules/features/<name>.nix` following the `mkEnableOption` / `mkIf` pattern above, import it from `modules/features/default.nix`, and enable it in the appropriate profiles or hosts.
- `stateVersion` is set to `"24.05"` across all hosts — do not change this without understanding Home Manager state version implications.
- SSH uses 1Password's identity agent (`~/.1password/agent.sock`). Git commits are signed with SSH keys via 1Password.

## References

- **Home Manager options**: https://nix-community.github.io/home-manager/options.xhtml — use this as the authoritative reference for supported Home Manager options. Always use this link as the source to look up module options.
