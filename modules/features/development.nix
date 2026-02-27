{ lib, pkgs, config, ... }:
{
  options.myConfig.development.enable =
    lib.mkEnableOption "Software development tools";

  config = lib.mkIf config.myConfig.development.enable {
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
    ];
  };
}
