{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.features.development;
  mcpDefaults = {
    kubernetes = true;
    nextcloud = true;
    todoist = true;
    circleci = false;
    serena = true;
    observe = false;
    jira = false;
  };
  # `//` right-biases onto mcpDefaults so hosts only need to override the keys
  # they care about; attrsOf's own `default` does not merge with definitions.
  mcp = mcpDefaults // cfg.mcp;
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
  circleci-cli = pkgs.circleci-cli.overrideAttrs (old: rec {
    version = "1.0.42707-pre";
    src = pkgs.fetchFromGitHub {
      owner = "CircleCI-Public";
      repo = "circleci-cli";
      rev = "v${version}";
      hash = "sha256-ltmRA8XlWFd8A2CD7bynpfyA3eab1sCRtRP8pPEvezw=";
    };
    vendorHash = "sha256-6FxItn+I2AyEQr7LMyUBcaDDOo/JE7g5tEF0o0VwE9Q=";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/CircleCI-Public/circleci-cli/version.Version=${version}"
      "-X github.com/CircleCI-Public/circleci-cli/version.Commit=v${version}"
      "-X github.com/CircleCI-Public/circleci-cli/version.packageManager=nix"
      "-buildid="
    ];
    # v1.0.x builds the binary as 'circleci' directly; v0.1.x built 'circleci-cli' and renamed it
    postInstall = ''
      installShellCompletion --cmd circleci \
        --bash <(HOME=$TMPDIR $out/bin/circleci completion bash --skip-update-check) \
        --zsh <(HOME=$TMPDIR $out/bin/circleci completion zsh --skip-update-check)
    '';
  });
in
{
  options.features.development = {
    enable = lib.mkEnableOption "Software development tools";

    gremlinSkillsPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Absolute path to a local gremlin-ai-skills checkout. Enables the gremlin-ai-skills-dev marketplace when non-empty, and (together with mcp.jira) the jira-mcp server.";
    };

    jiraEmail = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Email address used for JIRA MCP integration.";
    };

    mcp = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = { };
      description = ''
        Which MCP servers to enable, keyed by server name, overriding the defaults
        (kubernetes, nextcloud, todoist, circleci, serena = true; observe, jira = false). jira
        additionally requires gremlinSkillsPath to be set.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets =
      lib.optionalAttrs mcp.observe {
        observe-auth-header = {
          sopsFile = ../../secrets/common.yaml;
        };
      }
      // lib.optionalAttrs (mcp.jira && cfg.gremlinSkillsPath != "") {
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
        commands = {
          code-review = ./files/claude-commands/code-review.md;
        };
        settings = {
          model = "claude-sonnet-4-6";
          tui = "default";
          skipAutoPermissionPrompt = true;
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
            "warp@claude-code-warp" = true;
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
      servers =
        lib.optionalAttrs mcp.kubernetes {
          kubernetes-mcp-server = {
            command = "npx";
            args = [
              "-y"
              "kubernetes-mcp-server@latest"
            ];
          };
        }
        // lib.optionalAttrs mcp.nextcloud {
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
        }
        // lib.optionalAttrs mcp.todoist {
          todoist = {
            "url" = "https://ai.todoist.net/mcp";
          };
        }
        // lib.optionalAttrs mcp.circleci {
          circleci = {
            command = lib.getExe circleci-cli;
            args = [
              "mcp"
              "start"
            ];
          };
        }
        // lib.optionalAttrs mcp.serena {
          serena = {
            command = lib.getExe pkgs.serena;
            args = [
              "start-mcp-server"
              "--context"
              "claude-code"
              "--project-from-cwd"
            ];
          };
        }
        // lib.optionalAttrs mcp.observe {
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
        // lib.optionalAttrs (mcp.jira && cfg.gremlinSkillsPath != "") {
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
      flox
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
      pnpm
      kyverno-chainsaw
      rabbitmqadmin-ng
      rustc
      shellcheck
      yamllint
    ];
  };
}
