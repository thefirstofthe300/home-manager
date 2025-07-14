{ config, pkgs, nixgl, ... }: {
  nixGL.packages = nixgl.packages;

  programs = {
    ghostty = {
      enable = false;
      package = (config.lib.nixGL.wrap pkgs.ghostty);
      enableZshIntegration = true;
      settings = {
        theme = "Afterglow";
      };
    };
  };
}
