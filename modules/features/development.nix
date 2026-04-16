{ lib, pkgs, config, ... }: {
  options.myConfig.development.enable =
    lib.mkEnableOption "Software development tools";

  config = lib.mkIf config.myConfig.development.enable {
    services = {
      ollama = {
        enable = true;
        acceleration = "cuda";
        environmentVariables = { OLLAMA_CONTEXT_LENGTH = "64000"; };
      };
    };
    programs = {
      claude-code = {
        enable = true;
        memory.text = ''
          @rules/RTK.md
        '';
        rules."git" = ''
          # Git Rules

          ## Branches
          Always create a new branch for a new feature or bugfix. Each branch should
          include the Jira ticket name in the title. If you are unclear about what ticket
          the work is associated with, prompt the user to provide it.

          ## Commit Messages
          All commits must follow the Conventional Commits v1.0.0 specification:

          ```
          <type>[optional scope]: <description>

          [optional body]

          [optional footer(s)]
          ```

          **Types:** `feat`, `fix`, `build`, `chore`, `ci`, `docs`, `style`, `refactor`, `perf`, `test`

          **Rules:**
          - Description is required, imperative mood, lowercase, no trailing period
          - Scope is optional: `feat(auth): add login endpoint`
          - Breaking changes: append `!` before the colon (`feat!:`) and/or add a `BREAKING CHANGE:` footer
          - Body and footers are separated from the preceding section by a blank line
        '';
        rules."RTK" = ''
          # RTK - Rust Token Killer

          **Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

          ## Meta Commands (always use rtk directly)

          ```bash
          rtk gain              # Show token savings analytics
          rtk gain --history    # Show command usage history with savings
          rtk discover          # Analyze Claude Code history for missed opportunities
          rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
          ```

          ## Installation Verification

          ```bash
          rtk --version         # Should show: rtk X.Y.Z
          rtk gain              # Should work (not "command not found")
          which rtk             # Verify correct binary
          ```

          ⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

          ## Hook-Based Usage

          All other commands are automatically rewritten by the Claude Code hook.
          Example: `git status` → `rtk git status` (transparent, 0 tokens overhead)

          Refer to CLAUDE.md for full command reference.
        '';
        hooks."rtk-rewrite.sh" = ''
          #!/usr/bin/env bash
          # rtk-hook-version: 3
          # RTK Claude Code hook — rewrites commands to use rtk for token savings.
          # Requires: rtk >= 0.23.0, jq
          #
          # This is a thin delegating hook: all rewrite logic lives in `rtk rewrite`,
          # which is the single source of truth (src/discover/registry.rs).
          # To add or change rewrite rules, edit the Rust registry — not this file.
          #
          # Exit code protocol for `rtk rewrite`:
          #   0 + stdout  Rewrite found, no deny/ask rule matched → auto-allow
          #   1           No RTK equivalent → pass through unchanged
          #   2           Deny rule matched → pass through (Claude Code native deny handles it)
          #   3 + stdout  Ask rule matched → rewrite but let Claude Code prompt the user

          if ! command -v jq &>/dev/null; then
            echo "[rtk] WARNING: jq is not installed. Hook cannot rewrite commands. Install jq: https://jqlang.github.io/jq/download/" >&2
            exit 0
          fi

          if ! command -v rtk &>/dev/null; then
            echo "[rtk] WARNING: rtk is not installed or not in PATH. Hook cannot rewrite commands. Install: https://github.com/rtk-ai/rtk#installation" >&2
            exit 0
          fi

          # Version guard: rtk rewrite was added in 0.23.0.
          # Older binaries: warn once and exit cleanly (no silent failure).
          RTK_VERSION=$(rtk --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
          if [ -n "$RTK_VERSION" ]; then
            MAJOR=$(echo "$RTK_VERSION" | cut -d. -f1)
            MINOR=$(echo "$RTK_VERSION" | cut -d. -f2)
            # Require >= 0.23.0
            if [ "$MAJOR" -eq 0 ] && [ "$MINOR" -lt 23 ]; then
              echo "[rtk] WARNING: rtk $RTK_VERSION is too old (need >= 0.23.0). Upgrade: cargo install rtk" >&2
              exit 0
            fi
          fi

          INPUT=$(cat)
          CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

          if [ -z "$CMD" ]; then
            exit 0
          fi

          # Delegate all rewrite + permission logic to the Rust binary.
          REWRITTEN=$(rtk rewrite "$CMD" 2>/dev/null)
          EXIT_CODE=$?

          case $EXIT_CODE in
            0)
              # Rewrite found, no permission rules matched — safe to auto-allow.
              # If the output is identical, the command was already using RTK.
              [ "$CMD" = "$REWRITTEN" ] && exit 0
              ;;
            1)
              # No RTK equivalent — pass through unchanged.
              exit 0
              ;;
            2)
              # Deny rule matched — let Claude Code's native deny rule handle it.
              exit 0
              ;;
            3)
              # Ask rule matched — rewrite the command but do NOT auto-allow so that
              # Claude Code prompts the user for confirmation.
              ;;
            *)
              exit 0
              ;;
          esac

          ORIGINAL_INPUT=$(echo "$INPUT" | jq -c '.tool_input')
          UPDATED_INPUT=$(echo "$ORIGINAL_INPUT" | jq --arg cmd "$REWRITTEN" '.command = $cmd')

          if [ "$EXIT_CODE" -eq 3 ]; then
            # Ask: rewrite the command, omit permissionDecision so Claude Code prompts.
            jq -n \
              --argjson updated "$UPDATED_INPUT" \
              '{
                "hookSpecificOutput": {
                  "hookEventName": "PreToolUse",
                  "updatedInput": $updated
                }
              }'
          else
            # Allow: rewrite the command and auto-allow.
            jq -n \
              --argjson updated "$UPDATED_INPUT" \
              '{
                "hookSpecificOutput": {
                  "hookEventName": "PreToolUse",
                  "permissionDecision": "allow",
                  "permissionDecisionReason": "RTK auto-rewrite",
                  "updatedInput": $updated
                }
              }'
          fi
        '';
        settings = {
          hooks = {
            PreToolUse = [{
              matcher = "Bash";
              hooks = [{
                type = "command";
                command = "bash /home/dseymour/.claude/hooks/rtk-rewrite.sh";
              }];
            }];
          };
          enabledPlugins = {
            "claude-code-setup@claude-plugins-official" = true;
            "slack@claude-plugins-official" = true;
            "code-review@claude-plugins-official" = true;
            "commit-commands@claude-plugins-official" = true;
            "feature-dev@claude-plugins-official" = true;
            "document-skills@anthropic-agent-skills" = true;
          };
          extraKnownMarketplaces = {
            "anthropic-agent-skills" = {
              "source" = {
                "source" = "github";
                "repo" = "anthropics/skills";
              };
            };
          };
        };
      };
      opencode = {
        enable = true;
        settings = {
          model = "ollama/gemma4:e2b";
          provider = {
            ollama = {
              name = "Ollama";
              options = { baseURL = "http://localhost:11434/v1"; };
              models = { "gemma4:e2b" = { name = "gemma4:e2b"; }; };
            };
          };
        };
      };
    };
    home.packages = with pkgs; [
      go
      python3
      cargo
      cargo-lambda
      protobuf
      ripgrep
      goreleaser
      pre-commit
      commitizen
      circleci-cli
      gh
      opencode
      rtk
    ];
  };
}
