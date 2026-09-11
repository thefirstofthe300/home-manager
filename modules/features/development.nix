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
    nextcloud = false;
    todoist = true;
    circleci = false;
    serena = false;
    observe = false;
    jira = false;
    github = true;
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
  beads = pkgs.beads.overrideAttrs (old: rec {
    version = "1.1.2";
    src = pkgs.fetchFromGitHub {
      owner = "gastownhall";
      repo = "beads";
      tag = "v${version}";
      hash = "sha256-5oDI2MunHrOKx1m5mC0ZaIqZ9+f1YBQotMBUj6U5H1I=";
    };
    vendorHash = "sha256-WWEwGpCwMPD7jaz02zN745RQQqYTQttehbcT3J9hayM=";
    # `go test -skip` only honors the last flag occurrence, so the added
    # test below must be folded into a single regex rather than appended as
    # a second -skip flag onto old.checkFlags.
    checkFlags =
      let
        skippedTests = [
          "TestCheckMetadataVersionTracking"
          # New in 1.1.2: exercises `git worktree add` triggering a
          # post-checkout hook, which can't exec in the Nix build sandbox.
          # Unrelated to this version bump.
          "TestInstallHooksBeads_WorktreeAccess"
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          "TestCleanupMergeArtifacts_CommandInjectionPrevention"
        ];
      in
      [ "-skip=^(${lib.concatStringsSep "|" skippedTests})$" ];
  });
  circleci-cli = pkgs.circleci-cli.overrideAttrs (old: rec {
    version = "1.0.49408";
    src = pkgs.fetchFromGitHub {
      owner = "CircleCI-Public";
      repo = "circleci-cli";
      rev = "v${version}";
      hash = "sha256-8vOMD7OCg5zEbqeOEEaBg4qT2vIWi/A961Ec1I9tzTg=";
    };
    vendorHash = "sha256-YvlDEgWmqUrLH9B5yV+1dImH1h3O7Ub3tgXSALiJLKI=";
    ldflags = [
      "-s"
      "-w"
      "-X main.version=${version}"
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
      description = "Absolute path to a local gremlin-ai-skills checkout. Enables the gremlin-ai-skills marketplace when non-empty, and (together with mcp.jira) the jira-mcp server.";
    };

    jiraEmail = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Email address used for JIRA MCP integration.";
    };

    workSkills = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Names of plugins to enable from the gremlin-ai-skills marketplace (requires
        gremlinSkillsPath to be set). These are work-only skills, e.g. "investigate-alert".
      '';
    };

    mcp = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = { };
      description = ''
        Which MCP servers to enable, keyed by server name, overriding the defaults
        (kubernetes, todoist, github = true; nextcloud, circleci, serena, observe,
        jira = false). jira additionally requires gremlinSkillsPath to be set. github
        uses GitHub's hosted MCP endpoint and authenticates over OAuth on first use.
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
      }
      // lib.optionalAttrs mcp.github {
        github-mcp-token = {
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
          model = "claude-sonnet-5";
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
          }
          // lib.optionalAttrs (cfg.gremlinSkillsPath != "") (
            lib.genAttrs (map (skill: "${skill}@gremlin-ai-skills") cfg.workSkills) (_: true)
          );
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
            "gremlin-ai-skills" = {
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
        }
        // lib.optionalAttrs mcp.github {
          github = {
            command = lib.getExe (
              pkgs.writeShellApplication {
                name = "github-mcp";
                runtimeInputs = [ pkgs.nodejs ];
                text = ''
                  headerFile=$(mktemp)
                  trap 'rm -f "$headerFile"' EXIT
                  printf 'Authorization: Bearer %s\n' "$(cat ${lib.escapeShellArg config.sops.secrets.github-mcp-token.path})" > "$headerFile"
                  chmod 600 "$headerFile"
                  npx mcp-remote@latest "https://api.githubcopilot.com/mcp/" --header-file "$headerFile"
                '';
              }
            );
          };
        };
    };

    home.packages = with pkgs; [
      beads
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
