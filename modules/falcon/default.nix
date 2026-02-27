{ pkgs, ... }: {
  imports = [ ../profiles/personal.nix ];

  myConfig.kubernetes.enable = true;

  nixpkgs.config.allowUnfreePredicate = (pkg: true);

  home = {
    username = "dseymour";
    homeDirectory = "/home/dseymour";
    stateVersion = "24.05";
    sessionPath = [ "/home/dseymour/.krew/bin" ];
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

  programs = {
    home-manager.enable = true;
    git.extraConfig.gpg.ssh.program =
      "${pkgs._1password-gui}/share/1password/op-ssh-sign";
  };

  services = {
    flatpak = {
      enable = true;
      packages = [
        "com.spotify.Client"
        "com.github.tchx84.Flatseal"
        "net.nokyan.Resources"
        "im.riot.Riot"
      ];
    };
  };
}
