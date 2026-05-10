{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      age
      sops
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
  xdg.autostart.enable = true;
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
