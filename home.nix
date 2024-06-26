{ config, pkgs, ... }:
{
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
      kubernetes-helm
      fluxcd
      tenv
      zsh-powerlevel10k
      zsh-you-should-use
    ];
    file = {
      p10k = {
        target = ".p10k.zsh";
        source = ./p10k.zsh;
      };
    };
    sessionVariables = {
      TENV_AUTO_INSTALL = "true";
    };
  };

  programs = {
    home-manager.enable = true;
    vim = {
      enable = true;
      defaultEditor = true;
      extraConfig = ''
        set nobackup
        set nowb
        set noswapfile
        colorscheme gruvbox
      '';
      plugins = with pkgs; [
        vimPlugins.gruvbox
        vimPlugins.vim-sensible
        vimPlugins.vim-terraform
      ];
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      initExtra = ''
        export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      '';

      shellAliases = {
        ll = "ls -l";
        update = "sudo nixos-rebuild switch";
      };
      history = {
        size = 10000;
        path = "${config.xdg.dataHome}/zsh/history";
      };

      plugins = [
        {
          name = "powerlevel10k";
          src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
        }
        {
          name = "you-should-use";
          src = "${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use";
        }
      ];
    };
  };
}
