{ config, pkgs, ... }:
{
  nixpkgs.config.allowUnfreePredicate = (pkg: true);

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
      velero
      talosctl
      kubectl
      krew
      kubernetes-helm
      fluxcd
      tenv
      zsh-powerlevel10k
      zsh-you-should-use
      (nerdfonts.override { fonts = [ "FiraCode" "Meslo" ]; })
      terraform-docs
      tflint
      tfsec
      aws-iam-authenticator
      noto-fonts
      istioctl
      clusterctl
      helm-docs
      kind
      operator-sdk
      (vscode-with-extensions.override {
        vscodeExtensions = with vscode-extensions; [
          jnoortheen.nix-ide
          ms-azuretools.vscode-docker
          redhat.vscode-yaml
        ];
      })
      nixpkgs-fmt
      direnv
    ];
    file = {
      p10k = {
        target = ".p10k.zsh";
        source = ./p10k.zsh;
      };
    };
    sessionPath = [
      "/home/dseymour/.krew/bin"
    ];
    sessionVariables = {
      TENV_AUTO_INSTALL = "true";
    };
  };


  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "FiraCode Nerd Font Mono"
        ];
      };
    };
  };

  dconf = {
    settings = {
      "org/gnome/desktop/interface" = {
        gtk-theme = "Adwaita-dark";
        icon-theme = "Adwaita";
        cursor-theme = "Adwaita";
        font-name = "Noto Sans 11";
        document-font-name = "Noto Serif 11";
        monospace-font-name = "FiraCode Nerd Font Mono 10";
      };
    };
  };

  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "Danny Seymour";
      userEmail = "danny@seymour.family";
      signing = {
        signByDefault = true;
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBLs1zuIf732rfBMxwN6ly3bWM+xNqPiw5ahLpTvVj7k";
      };

      extraConfig = {
        gpg = {
          format = "ssh";
        };
      };
    };
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
        source ${config.home.homeDirectory}/.p10k.zsh
        source ${config.home.homeDirectory}/.config/op/plugins.sh

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
    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };
}
