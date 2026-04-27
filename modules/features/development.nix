{ lib, pkgs, config, ... }: {
  options.myConfig.development.enable =
    lib.mkEnableOption "Software development tools";

  config = lib.mkIf config.myConfig.development.enable {
    programs = {
      claude-code = {
        enable = true;
        context = ''
          @rules/git.md
        '';
        rules."git" = ''
          # Git Rules

          ## Branches
          Always create a new branch for a new feature or bugfix that includes a Jira ticket
          in the branch name. If you are unclear about what ticket the work is associated with, 
          prompt the user to provide it.

          Example:

          ```
          <Jira_ticket>/<description>
          ```

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
        mcpServers = {
          kubernetes-mcp-server = {
            command = "npx";
            args = [
              "-y"
              "kubernetes-mcp-server@latest"
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
    ];
  };
}
