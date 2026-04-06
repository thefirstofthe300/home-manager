{ lib, pkgs, config, ... }:
{
  options.myConfig.development.enable =
    lib.mkEnableOption "Software development tools";

  config = lib.mkIf config.myConfig.development.enable {
    programs = {
      claude-code = {
        enable = true;
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
    ];
  };
}
