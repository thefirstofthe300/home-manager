{ lib, pkgs, config, ... }:
{
  options.myConfig.sbom.enable =
    lib.mkEnableOption "Software supply chain and SBOM tools";

  config = lib.mkIf config.myConfig.sbom.enable {
    home.packages = with pkgs; [
      syft
      diffoci
      regctl
      cyclonedx-gomod
      source-meta-json-schema
    ];
  };
}
