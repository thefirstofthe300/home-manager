{ config, pkgs, nixgl, ... }: {
  programs = {
    ghostty = {
      enable = true;
      enableZshIntegration = true;
      installVimSyntax = true;
      settings = {
        theme = "Afterglow";
      };
    };
  };
}
