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
- **falcon** (personal): All four features enabled, krew for kubectl plugins
- **iron-man** (personal): `development` feature only, GNOME dconf theme settings

### Flake Inputs

- `nixpkgs` (unstable), `home-manager`, `nixGL` (GPU on non-NixOS), `nix-flatpak`

## Conventions

- **Adding a new tool/package**: If it's broadly useful, add to `modules/common/packages.nix`. If it belongs to a feature domain, add to the appropriate `modules/features/*.nix`. If host-specific, add to `modules/<host>/default.nix`.
- **Adding a new feature module**: Create `modules/features/<name>.nix` following the `mkEnableOption` / `mkIf` pattern above, import it from `modules/features/default.nix`, and enable it in the appropriate profiles or hosts.
- `stateVersion` is set to `"24.05"` across all hosts — do not change this without understanding Home Manager state version implications.
- SSH uses 1Password's identity agent (`~/.1password/agent.sock`). Git commits are signed with SSH keys via 1Password.

## Dotfiles

**Always make dotfile changes through this repo's Nix home-manager modules, not by editing dotfiles directly.** Home Manager owns any file it manages — direct edits will be overwritten on the next `home-manager switch`.

To check whether a dotfile is home-manager-managed, verify it's a symlink into the Nix store:

```bash
readlink ~/.someconfig  # managed if it points to /nix/store/...
```

Only edit a dotfile directly if home-manager has no module option for that configuration. In that case, use `home.file` or `xdg.configFile` in the appropriate module to manage it as a raw file through Nix instead, if possible. Consult the [Home Manager options reference](https://nix-community.github.io/home-manager/options.xhtml) before concluding a setting is unsupported.

## References

- **Home Manager options**: https://nix-community.github.io/home-manager/options.xhtml — use this as the authoritative reference for supported Home Manager options. Always use this link as the source to look up module options.

<!-- claude-mem-lite:begin v1 -->
## claude-mem-lite — persistent memory

PreToolUse hooks already run `mem_recall` for past lessons before Read/Edit/Write. The calls worth making proactively:

| When | Call |
|------|------|
| Before Edit/Write | hook already recalled; if a `#NN` lesson was injected, cite `#NN` next time you produce user-visible text (citing = adopting the feedback; uncited lessons decay) |
| After fixing a non-trivial bug | `mem_save(type="bugfix", lesson_learned="<root cause + fix>", importance=2)` |
| After a non-obvious architecture decision | `mem_save(type="decision", lesson_learned="<constraint + tradeoff>")` |
| Deferring to a future session | `mem_defer({title, priority:1|2|3, detail})`; when fixed, add `closes_deferred=[N]` to `mem_save` |
| Looking up past work / history | `mem_search "keywords"` · `mem_recent` · `mem_timeline` |

Path cost is round-trips, not milliseconds: the PreToolUse hook above already recalls (0 calls) — prefer it. For an explicit query, if these `mem_*` tools are deferred behind ToolSearch this session, the Bash CLI `claude-mem-lite` is one call vs two (ToolSearch + call); the MCP server instructions carry the absolute path to use when it is not on PATH.

Full tool + CLI tables, citation/decay rules, and save discipline → `.claude/plugin_claude_mem_lite.md`
<!-- claude-mem-lite:end -->
