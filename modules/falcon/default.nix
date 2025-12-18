{ pkgs, ... }: {
  nixpkgs.config.allowUnfreePredicate = (pkg: true);

  home = {
    username = "dseymour";
    homeDirectory = "/home/dseymour";
    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "24.05";

    packages = with pkgs; [
      velero
      talosctl
      direnv
      kubeseal
      kind
    ];
    sessionPath = [ "/home/dseymour/.krew/bin" ];
    sessionVariables = { TENV_AUTO_INSTALL = "true"; };
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
    git = {
      enable = true;
      includes = [{
        contents = {
          user = {
            name = "Danny Seymour";
            email = "danny@seymour.family";
            signingKey =
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBLs1zuIf732rfBMxwN6ly3bWM+xNqPiw5ahLpTvVj7k";
          };
          gpg = {
            format = "ssh";
            ssh = {
              program = "${pkgs._1password-gui}/share/1password/op-ssh-sign";
            };
          };
          commit = { 
            gpgSign = true; 
          };
        };
      }];
    };
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
