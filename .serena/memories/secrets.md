# Secrets (sops-nix)

- `modules/common/secrets.nix` sets `sops.age.keyFile` to
  `~/.config/sops/age/keys.txt` and adds a HM activation script (`entryBefore [ "sops" ]`) that
  fetches the age private key from 1Password (`op read "op://Private/SOPS Age Key/private key"`,
  requires `op` CLI + `XDG_RUNTIME_DIR`) if the key file doesn't already exist locally. Failure to
  fetch just warns and leaves the key file empty — it doesn't hard-fail activation.
- `.sops.yaml` currently registers only one age recipient key, aliased `&beefcake`, for
  `secrets/*.yaml`. Other hosts (falcon, iron-man) have no age key of their own registered yet.
- Actual secrets live in `secrets/common.yaml` (sops-encrypted) and are declared per-consumer via
  `sops.secrets.<name> = { sopsFile = ../../secrets/common.yaml; }` inside whichever module needs
  them (e.g. `hf-token`, `gremlin-api-key` in `modules/beefcake/default.nix`; `observe-auth-header`,
  `jira-api-token` conditionally in `modules/features/development.nix`). Decrypted paths are read at
  activation time via `config.sops.secrets.<name>.path`.
