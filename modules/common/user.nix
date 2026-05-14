{
  lib,
  pkgs,
  ...
}:
{
  home = {
    username = "dseymour";
    homeDirectory = "/home/dseymour";
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;

  # All hosts allow unfree; host modules may add CUDA/nvidia-specific keys alongside this.
  nixpkgs.config.allowUnfreePredicate = lib.mkDefault (_pkg: true);

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      emoji = [ "Noto Emoji" ];
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "FiraCode Nerd Font Mono" ];
    };
  };

  # All hosts sign git commits via 1Password SSH agent.
  programs.git.settings.gpg.ssh.program = "${pkgs._1password-gui}/share/1password/op-ssh-sign";
}
