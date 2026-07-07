# Suggested Commands

```bash
# Apply config for the current host (only real way to validate changes)
home-manager switch --flake .#dseymour@<hostname>   # beefcake | falcon | iron-man

# Update flake inputs (regenerates flake.lock; entries interleave across unrelated commits —
# expect flake.lock diffs alongside otherwise-unrelated feature commits)
nix flake update

# Cheap syntax/eval check without a full activation
nix flake check
```

No project-specific test/lint/format commands exist. `home-manager switch` is the task-completion gate.
