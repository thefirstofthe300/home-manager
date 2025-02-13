{ pkgs, ... }: {
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
      fluxcd
      zsh-powerlevel10k
      zsh-you-should-use
      nerd-fonts.fira-code
      meslo-lgs-nf
      noto-fonts
      (vscode-with-extensions.override {
        vscodeExtensions = with vscode-extensions; [
          jnoortheen.nix-ide
          ms-azuretools.vscode-docker
          redhat.vscode-yaml
          golang.go
          mkhl.direnv
          ms-vscode.makefile-tools
          rust-lang.rust-analyzer
          hashicorp.terraform
        ];
      })
      nil
      nixfmt-classic
      direnv
      tenv
      terraform-docs
      tflint
      tfsec
      aws-iam-authenticator
      istioctl
      clusterctl
      helm-docs
      kind
      minikube
    ];
    sessionVariables = { TENV_AUTO_INSTALL = "true"; };
  };

  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        emoji = [ "Noto Emoji" ];
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "FiraCode Nerd Font Mono" ];
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
      userEmail = "danny.seymour@gremlin.com";
      signing = {
        signByDefault = true;
        key =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBLs1zuIf732rfBMxwN6ly3bWM+xNqPiw5ahLpTvVj7k";
      };

      extraConfig = { gpg = { format = "ssh"; }; };
    };
    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };

  services = {
    flatpak = {
      enable = true;
      packages = [
        "com.slack.Slack"
        "com.spotify.Client"
        "com.github.tchx84.Flatseal"
        "net.nokyan.Resources"
        "im.riot.Riot"
      ];
    };
  };
}
