{ pkgs, ... }: {
  imports = [ ../profiles/work.nix ];

  myConfig.kubernetes.enable = true;

  nixpkgs.config = { allowUnfreePredicate = (pkg: true); };

  home = {
    username = "dseymour";
    homeDirectory = "/home/dseymour";
    stateVersion = "24.05";

    packages = with pkgs; [
      claude-code
      tex-fmt
      nil
      nixfmt-classic
      jetbrains.idea
    ];
  };

  targets.genericLinux = {
    enable = true;
  };

  programs.home-manager.enable = true;

  services = {
    flatpak = {
      enable = true;
      update = {
        auto = {
          enable = true;
          onCalendar = "daily";
        };
      };
      packages = [
        "com.slack.Slack"
        "com.spotify.Client"
        "com.github.tchx84.Flatseal"
        "net.nokyan.Resources"
        "im.riot.Riot"
        "com.fastmail.Fastmail"
      ];
    };
  };
}
