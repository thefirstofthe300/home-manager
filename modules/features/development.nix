{ lib, pkgs, config, ... }:
{
  options.myConfig.development.enable =
    lib.mkEnableOption "Software development tools";

  config = lib.mkIf config.myConfig.development.enable {
    services = {
      ollama = {
        enable = true;
        acceleration = "cuda";
        environmentVariables = {
          OLLAMA_CONTEXT_LENGTH = "64000";
        };
      };
    };
    programs = {
      claude-code = {
        enable = true;
      };
      opencode = {
        enable = true;
        settings = {
          model = "ollama/gemma4:e4b";
          provider = {
            ollama = {
              name = "Ollama";
              options = {
                baseURL = "http://localhost:11434/v1";
              };
              models = {
                "gemma4:e4b" = {
                  name = "gemma4:e4b";
                };
              };
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
    ];
  };
}
