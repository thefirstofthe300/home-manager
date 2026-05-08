{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.myConfig.development.enable = lib.mkEnableOption "Software development tools";

  config = lib.mkIf config.myConfig.development.enable {
    sops.secrets.jira-api-token = {
      sopsFile = ../../secrets/common.yaml;
    };

    programs = {
      claude-code = {
        enable = true;
        enableMcpIntegration = true;
        context = ./files/claude-context/CLAUDE.md;
        rulesDir = ./files/claude-rules;
        skills = ./files/claude-skills;
        settings = {
          model = "claude-sonnet-4-6";
          permissions = {
            defaultMode = "auto";
            allow = [
              "Read"
              "Glob"
              "Grep"
              "Bash(ls)"
              "Bash(find)"
              "Bash(grep)"
              "Bash(head)"
              "Bash(tail)"
            ];
          };
          enabledPlugins = {
            "claude-mem@thedotmack" = true;
            "claude-code-setup@claude-plugins-official" = true;
            "slack@claude-plugins-official" = true;
            "code-review@claude-plugins-official" = true;
            "commit-commands@claude-plugins-official" = true;
            "feature-dev@claude-plugins-official" = true;
            "document-skills@anthropic-agent-skills" = true;
            "gitops-skills@fluxcd" = true;
          };
          extraKnownMarketplaces = {
            "anthropic-agent-skills" = {
              "source" = {
                "source" = "github";
                "repo" = "anthropics/skills";
              };
            };
            "fluxcd" = {
              "source" = {
                "source" = "github";
                "repo" = "fluxcd/agent-skills";
              };
            };
            "gremlin-ai-skills-dev" = {
              "source" = {
                "source" = "directory";
                "path" = "/home/dseymour/workspace/github.com/gremlin/gremlin-ai-skills";
              };
            };
            "thedotmack" = {
              "source" = {
                "source" = "github";
                "repo" = "thedotmack/claude-mem";
              };
            };
          };
        };
      };
    };
    programs.mcp = {
      enable = true;
      servers = {
        jira-mcp = {
          command = lib.getExe (
            pkgs.writeShellApplication {
              name = "jira-mcp";
              runtimeInputs = [ pkgs.nodejs ];
              text = ''
                JIRA_API_TOKEN=$(cat ${lib.escapeShellArg config.sops.secrets.jira-api-token.path})
                export JIRA_API_TOKEN
                exec npx /home/dseymour/workspace/github.com/gremlin/gremlin-ai-skills/ENG/jira-mcp/dist/server.js "$@"
              '';
            }
          );
          env = {
            JIRA_BASE_URL = "https://gremlininc.atlassian.net";
            JIRA_EMAIL = "danny.seymour@gremlin.com";
          };
        };
        kubernetes-mcp-server = {
          command = "npx";
          args = [
            "-y"
            "kubernetes-mcp-server@latest"
          ];
        };
        nextcloud = {
          command = "npx";
          args = [
            "mcp-remote"
            "https://cloud-mcp.seymour.family/mcp"
            "3334"
            "--static-oauth-client-info"
            "@/home/dseymour/.config/mcp-remote/nextcloud-oauth.json"
          ];
        };
        mcp-search = {
          command = lib.getExe (
            pkgs.writeShellScriptBin "claude-mem-mcp" ''
              export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib"
              _C="''${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
              _E="''${CLAUDE_PLUGIN_ROOT:-''${PLUGIN_ROOT:-}}"
              _P=$(
                {
                  [ -n "$_E" ] && printf '%s\n' "$_E"
                  printf '%s\n' "$PWD/plugin" "$PWD"
                  ls -dt \
                    "$HOME/.codex/plugins/cache/claude-mem-local/claude-mem"/[0-9]*/ \
                    "$HOME/.codex/plugins/cache/thedotmack/claude-mem"/[0-9]*/ \
                    "$_C/plugins/cache/thedotmack/claude-mem"/[0-9]*/ 2>/dev/null
                  printf '%s\n' "$_C/plugins/marketplaces/thedotmack/plugin"
                } | while IFS= read -r _R; do
                  _R="''${_R%/}"
                  [ -d "$_R/plugin/scripts" ] && _Q="$_R/plugin" || _Q="$_R"
                  [ -f "$_Q/scripts/mcp-server.cjs" ] && { printf '%s\n' "$_Q"; break; }
                done
              )
              [ -n "$_P" ] || { echo "claude-mem: mcp server not found" >&2; exit 1; }
              exec ${pkgs.nodejs}/bin/node "$_P/scripts/mcp-server.cjs"
            ''
          );
        };
      };
    };

    home.packages = with pkgs; [
      bun
      go
      golangci-lint
      uv
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
      yq
      kubeconform
      kustomize
      nodejs
      kyverno-chainsaw
      rabbitmqadmin-ng
      rustc
    ];
  };
}
