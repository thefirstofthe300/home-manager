# Conventions

- Feature module pattern (`modules/features/*.nix`): `options.features.<name>.enable = lib.mkEnableOption
  "<description>"`, then `config = lib.mkIf config.features.<name>.enable { ... }`. Follow this exactly
  for new feature modules; register the import in `modules/features/default.nix`; enable from a
  profile (`modules/profiles/*.nix`) or a specific host module.
- Placement rule for new packages: broadly useful -> `modules/common/packages.nix`; belongs to a
  feature domain -> that `modules/features/*.nix`; host-specific -> `modules/<host>/default.nix`.
- Per-key boolean override maps (see `mcpDefaults // cfg.mcp` in development.nix): use `//` right-biased
  merge onto a `let`-bound defaults attrset, exposed as `lib.types.attrsOf lib.types.bool` with an
  empty `default = { }` — `attrsOf`'s own default does NOT merge with definitions, so the merge must
  be done manually in `let`.
- Dotfiles are only ever edited through this repo's HM modules (`home.file` / `xdg.configFile`), never
  by hand — HM overwrites direct edits on next `switch`. Check `readlink` on a dotfile to confirm it's
  HM-managed before assuming it needs a raw edit.
- Custom/pre-release package overrides live inline in a `let` block of the consuming host or feature
  module (e.g. `circleci-cli` pre-release override in `modules/features/development.nix`,
  `devfiler` rust package build in `modules/beefcake/default.nix`), not in a separate overlay file.
