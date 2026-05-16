{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.features.development;
  # uvx wrapper that injects libstdc++ and zlib only when spawning chroma-mcp,
  # so the Nix python3.13 linker can find them without polluting the global env.
  uvxChromaWrapper = pkgs.writeShellScriptBin "uvx" ''
    if [[ "$*" == *chroma-mcp* ]]; then
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
    exec ${pkgs.uv}/bin/uvx "$@"
  '';
  uvWithChromaFix = pkgs.symlinkJoin {
    name = "uv-with-chroma-uvx-fix";
    paths = [
      uvxChromaWrapper
      pkgs.uv
    ];
  };
in
{
  options.features.development = {
    enable = lib.mkEnableOption "Software development tools";

    gremlinSkillsPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Absolute path to a local gremlin-ai-skills checkout. Enables the gremlin-ai-skills-dev marketplace and jira-mcp server when non-empty.";
    };

    jiraEmail = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Email address used for JIRA MCP integration.";
    };

    enableObserveMcp = lib.mkEnableOption "Observe MCP server";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets =
      lib.optionalAttrs cfg.enableObserveMcp {
        observe-auth-header = {
          sopsFile = ../../secrets/common.yaml;
        };
      }
      // lib.optionalAttrs (cfg.gremlinSkillsPath != "") {
        jira-api-token = {
          sopsFile = ../../secrets/common.yaml;
        };
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
            "thedotmack" = {
              "source" = {
                "source" = "github";
                "repo" = "thedotmack/claude-mem";
              };
            };
          }
          // lib.optionalAttrs (cfg.gremlinSkillsPath != "") {
            "gremlin-ai-skills-dev" = {
              "source" = {
                "source" = "directory";
                "path" = cfg.gremlinSkillsPath;
              };
            };
          };
        };
      };
    };

    programs.mcp = {
      enable = true;
      servers = {
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
            "mcp-remote@latest"
            "https://cloud-mcp.seymour.family/mcp"
            "3334"
            "--static-oauth-client-info"
            "@${config.xdg.configHome}/mcp-remote/nextcloud-oauth.json"
          ];
        };
        mcp-search = {
          command = "npx";
          args = [
            "-y"
            "claude-mem@latest"
          ];
          env = { };
        };
        todoist = {
          "url" = "https://ai.todoist.net/mcp";
        };
      }
      // lib.optionalAttrs cfg.enableObserveMcp {
        observe = {
          command = lib.getExe (
            pkgs.writeShellApplication {
              name = "observe-mcp";
              runtimeInputs = [ pkgs.nodejs ];
              text = ''
                AUTH_HEADER=$(cat ${lib.escapeShellArg config.sops.secrets.observe-auth-header.path})
                exec npx mcp-remote@latest "https://136981668482.observeinc.com/v1/ai/mcp" --header "Authorization:$AUTH_HEADER"
              '';
            }
          );
        };
      }
      // lib.optionalAttrs (cfg.gremlinSkillsPath != "") {
        jira-mcp = {
          command = lib.getExe (
            pkgs.writeShellApplication {
              name = "jira-mcp";
              runtimeInputs = [ pkgs.nodejs ];
              text = ''
                JIRA_API_TOKEN=$(cat ${lib.escapeShellArg config.sops.secrets.jira-api-token.path})
                export JIRA_API_TOKEN
                exec npx ${cfg.gremlinSkillsPath}/ENG/jira-mcp/dist/server.js "$@"
              '';
            }
          );
          env = {
            JIRA_BASE_URL = "https://gremlininc.atlassian.net";
            JIRA_EMAIL = cfg.jiraEmail;
          };
        };
      };
    };

    home.packages = with pkgs; [
      cobra-cli
      bun
      uvWithChromaFix
      go
      golangci-lint
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
