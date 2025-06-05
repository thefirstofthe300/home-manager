{ pkgs, ... }: {
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    fluxcd
    nerd-fonts.fira-code
    meslo-lgs-nf
    noto-fonts
    zsh-powerlevel10k
    zsh-you-should-use
    gnomeExtensions.clipboard-history
    gnomeExtensions.caffeine
    gnomeExtensions.appindicator
  ];
  home.enableNixpkgsReleaseCheck = false;
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
