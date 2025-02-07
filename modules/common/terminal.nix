{ config, pkgs, nixgl, ... }: {
  nixGL.packages = nixgl.packages;

  programs = {
    ghostty = {
      enable = true;
      package = (config.lib.nixGL.wrap pkgs.ghostty);
    };
  };
}
