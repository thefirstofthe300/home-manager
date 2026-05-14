{ config, ... }:
{
  imports = [ ../profiles/personal.nix ];

  features.kubernetes.enable = true;
  features.development.enable = true;
  features.cloud.enable = true;
  features.sbom.enable = true;

  home.sessionPath = [ "/home/dseymour/.krew/bin" ];

  programs.direnv.nix-direnv.enable = true;

  xdg.autostart.entries = [
    "${config.home.homeDirectory}/.local/share/flatpak/exports/share/applications/im.riot.Riot.desktop"
  ];

  services.flatpak = {
    enable = true;
    packages = [
      "com.spotify.Client"
      "com.github.tchx84.Flatseal"
      "net.nokyan.Resources"
      "im.riot.Riot"
    ];
  };
}
