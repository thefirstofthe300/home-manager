{ pkgs, config, ... }: {
  home = {
    packages = with pkgs; [
      nerd-fonts.fira-code
      meslo-lgs-nf
      noto-fonts
      zsh-powerlevel10k
      zsh-you-should-use
      gnupg
      direnv
      nil
      nixfmt
    ];
    enableNixpkgsReleaseCheck = false;
  };
  xdg = {
    autostart = {
      enable = true;
      entries = [
        "${config.home.homeDirectory}/.local/share/flatpak/exports/share/applications/im.riot.Riot.desktop"
      ];
    };
  };
  services = {
    home-manager = {
      autoExpire = {
        enable = true;
        store = {
          cleanup = true;
        };
      };
    };
  };
}
