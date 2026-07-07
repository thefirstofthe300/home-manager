# MCP Servers (modules/features/development.nix)

- `programs.claude-code` (HM module) configures claude-code itself: context file, rulesDir, skills,
  commands, settings (model, tui, permissions, `enabledPlugins`, `extraKnownMarketplaces`).
  `settings.permissions.defaultMode = "auto"` + `skipAutoPermissionPrompt = true` are already set here
  — this is the durable "auto mode" opt-in for this machine, not a per-session toggle.
- `programs.mcp.servers` is the separate HM option that actually registers MCP servers (consumed by
  claude-code via `enableMcpIntegration = true`).
- Which servers are active is controlled by `cfg.mcp = mcpDefaults // cfg.mcp` (see `mem:conventions`
  for the merge pattern) — defaults: kubernetes, nextcloud, todoist, serena = true; circleci,
  observe, jira = false. Hosts override via `features.development.mcp = { ... }` (e.g. beefcake turns
  on observe/jira/circleci).
- `jira` additionally requires `features.development.gremlinSkillsPath` to be set (non-empty) — it
  runs `<gremlinSkillsPath>/ENG/jira-mcp/dist/server.js` from a local checkout, not a published
  package. Same `gremlinSkillsPath` also gates the `gremlin-ai-skills-dev` claude-code marketplace.
- Servers needing tokens (`observe`, `jira-mcp`) wrap `npx` in a `pkgs.writeShellApplication` that
  reads the token from the sops-decrypted secret path at runtime and exports it as an env var —
  see `mem:secrets` for how those secrets are declared.
- `serena`/`flox` packages come from the flake's own inputs via the nixpkgs overlay in `flake.nix`
  (not nixpkgs proper) — check `flake.nix` overlay if either package needs a version bump.
- A `uvx` wrapper (`uvxChromaWrapper`) is defined here solely to inject `LD_LIBRARY_PATH` (libstdc++,
  zlib) when spawning `chroma-mcp`, working around the Nix python3.13 linker not finding those libs.
