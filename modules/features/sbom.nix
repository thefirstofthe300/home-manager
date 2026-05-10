{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.features.sbom.enable = lib.mkEnableOption "Software supply chain and SBOM tools";

  config = lib.mkIf config.features.sbom.enable {
    home.packages = with pkgs; [
      syft
      diffoci
      regctl
      cyclonedx-gomod
      source-meta-json-schema
    ];
  };
}
