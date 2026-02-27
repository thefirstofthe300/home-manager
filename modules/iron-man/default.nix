{ ... }: {
  imports = [ ../profiles/personal.nix ];

  nixpkgs.config.allowUnfreePredicate = (pkg: true);

  home = {
    username = "dseymour";
    homeDirectory = "/home/dseymour";
    stateVersion = "24.05";
  };

  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        emoji = [ "Noto Emoji" ];
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "FiraCode Nerd Font Mono" ];
      };
    };
  };

  dconf = {
    settings = {
      "org/gnome/desktop/interface" = {
        gtk-theme = "Adwaita-dark";
        icon-theme = "Adwaita";
        cursor-theme = "Adwaita";
        font-name = "Noto Sans 11";
        document-font-name = "Noto Serif 11";
        monospace-font-name = "FiraCode Nerd Font Mono 10";
      };
    };
  };

  programs.home-manager.enable = true;

  services = {
    flatpak = {
      enable = true;
      packages = [
        "com.spotify.Client"
        "com.github.tchx84.Flatseal"
        "net.nokyan.Resources"
      ];
    };
  };
}
