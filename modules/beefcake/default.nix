{ pkgs, ... }: {
  imports = [ ../profiles/work.nix ];

  myConfig.kubernetes.enable = true;

  nixpkgs.config = { 
    allowUnfree = true;
    allowUnfreePredicate = (pkg: true);
    nvidia.acceptLicense = true;
  };

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
    gpu ={
      enable = true;
      nvidia = {
        enable = true;
        version = "580.126.18";
        sha256 = "sha256-p3gbLhwtZcZYCRTHbnntRU0ClF34RxHAMwcKCSqatJ0=";
      };
    };
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
