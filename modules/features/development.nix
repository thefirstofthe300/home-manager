{ lib, pkgs, config, ... }: {
  options.myConfig.development.enable =
    lib.mkEnableOption "Software development tools";

  config = lib.mkIf config.myConfig.development.enable {
    programs = {
      claude-code = {
        enable = true;
        context = ./files/claude-context/CLAUDE.md;
        rulesDir = ./files/claude-rules;
        skills = ./files/claude-skills;
        mcpServers = {
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
        };
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
          };
        };
      };
    };
    home.packages = with pkgs; [
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
