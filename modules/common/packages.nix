{ pkgs, ... }: {
  home = {
    packages = with pkgs; [
      kubectl
      kubernetes-helm
      fluxcd
      nerd-fonts.fira-code
      meslo-lgs-nf
      noto-fonts
      zsh-powerlevel10k
      zsh-you-should-use
      signal-desktop
    ];
    enableNixpkgsReleaseCheck = false;
  };
  xdg = {
    autostart = {
      enable = true;
      entries = [
        "${pkgs.signal-desktop}/share/applications/signal.desktop"
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
