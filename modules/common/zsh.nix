{ config, pkgs,  ... }: {
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      dotDir = "${config.xdg.configHome}/zsh";

      initContent = ''
        export PATH="$PATH:${config.home.homeDirectory}/.local/bin"
        export TENV_DETACHED_PROXY=false
        export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source ${config.home.homeDirectory}/.p10k.zsh

        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word
      '';

      shellAliases = {
        ll = "ls -l";
        update = "home-manager switch";
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
