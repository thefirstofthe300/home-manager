# Task Completion

No linter/formatter/test runner is configured. To consider a change done:

1. `nix flake check` — fast eval-level sanity check.
2. `home-manager switch --flake .#dseymour@<hostname>` for the host actually being changed
   (or the host the user is working on) — this is the real validation; it both builds and activates.

There is nothing else to run. Do not invent lint/test commands for this repo.
