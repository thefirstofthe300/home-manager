{ pkgs, ... }: {
  imports = [ ../profiles/work.nix ];

  nixpkgs.config = { 
    allowUnfree = true;
    allowUnfreePredicate = (pkg: true);
    nvidia.acceptLicense = true;
    cudaSupport = true;
  };

  home = {
    username = "dseymour";
    homeDirectory = "/home/dseymour";
    stateVersion = "24.05";

    packages = with pkgs; [
      nil
      nixfmt
      jetbrains.idea
    ];
  };

  targets.genericLinux = {
    gpu ={
      enable = true;
      nvidia = {
        enable = true;
        version = "595.58.03";
        sha256 = "sha256-jA1Plnt5MsSrVxQnKu6BAzkrCnAskq+lVRdtNiBYKfk=";
      };
    };
  };

  programs = {
    home-manager = {
      enable = true;
    };
  };

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
