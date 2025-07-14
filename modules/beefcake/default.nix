{ pkgs, ... }: {
  nixpkgs.config = { allowUnfreePredicate = (pkg: true); };

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
#      (vscode-with-extensions.override {
#        vscodeExtensions = with vscode-extensions;
#          [
#            jnoortheen.nix-ide
#            ms-azuretools.vscode-docker
#            redhat.vscode-yaml
#            golang.go
#            mkhl.direnv
#            ms-vscode.makefile-tools
#            rust-lang.rust-analyzer
#            hashicorp.terraform
#            github.copilot
#            stkb.rewrap
#            visualstudioexptteam.vscodeintellicode
#            redhat.java
#            vscjava.vscode-java-debug
#            vscjava.vscode-java-test
#            vscjava.vscode-java-dependency
#            vscjava.vscode-gradle
#            ms-python.python
#            ms-python.black-formatter
#            ms-vscode-remote.remote-containers
#            ms-vscode-remote.remote-ssh
#          ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [{
#            name = "circleci";
#            publisher = "circleci";
#            version = "2.10.1";
#            sha256 = "yQuL4nunX8XkAurbw5ks78jU8zyxkOuy4Row0TK51SY=";
#          }
#          {
#            name = "copilot-chat";
#            publisher = "github";
#            version = "0.28.1";
#            sha256 = "xOv1JYhE9Q8zRXoZVs/W1U58+SdbJwR5y354LLfKeDQ=";
#          }];
#      })
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
      circleci-cli
      cargo
      cargo-lambda
      ripgrep
      protobuf
      go
      goreleaser
      python3
      cyclonedx-gomod
      diffoci
      regctl
      (google-cloud-sdk.withExtraComponents
        ([ google-cloud-sdk.components.gke-gcloud-auth-plugin ]))
      aws-sam-cli
    ];
    sessionVariables = { TENV_AUTO_INSTALL = "true"; };
  };

  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        emoji = [ "Noto Emoji" ];
        serif = [ "Noto Serif" ];
        sansSerif = [ "Adwaita Sans" ];
        monospace = [ "Adwaita Mono" ];
      };
    };
  };

  dconf = {
    settings = {
      "org/gnome/desktop/interface" = {
        gtk-theme = "Adwaita-dark";
        icon-theme = "Adwaita";
        cursor-theme = "Adwaita";
        font-name = "Adwaita Sans 11";
        document-font-name = "Noto Serif 11";
        monospace-font-name = "Adwaita Mono 10";
      };
    };
  };

  programs = {
    home-manager.enable = true;
    jqp.enable = true;
    git = {
      enable = true;
      userName = "Danny Seymour";
      userEmail = "danny.seymour@gremlin.com";
      signing = {
        signByDefault = true;
        key =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBLs1zuIf732rfBMxwN6ly3bWM+xNqPiw5ahLpTvVj7k";
      };

      extraConfig = {
        gpg = { format = "ssh"; };
        http = { cookieFile = "~/.gitcookies"; };
      };
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
        "us.zoom.Zoom"
      ];
    };
  };
}
