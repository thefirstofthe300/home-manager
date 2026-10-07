{
  description = "Home Manager configuration for Daniel Seymour";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    serena = {
      url = "github:oraios/serena";
    };
    claude-desktop-debian = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nixgl,
      nix-flatpak,
      sops-nix,
      serena,
      claude-desktop-debian,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            serena = serena.packages.${system}.serena;
            # Pinned ahead of the upstream flake, which lags the official .deb
            # release. Drop the override once claude-desktop-debian catches up.
            claude-desktop = claude-desktop-debian.packages.${system}.claude-desktop.overrideAttrs (old: rec {
              version = "2.26454.2";
              src = final.fetchurl {
                url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
                hash = "sha256-slGgIkqGNYdPM1mN+O2JUrQn+EgV7llYDMAi1r2yQw8=";
              };
            });
            # nixpkgs-unstable lags the upstream claude-code release by a few
            # days; override to the latest release until nixpkgs catches up.
            # Bump version/checksum from https://downloads.claude.ai/claude-code-releases/latest
            claude-code = prev.claude-code.override {
              manifest = {
                version = "2.1.285";
                platforms.linux-x64 = {
                  binary = "claude.zst";
                  checksum = "e88a8b40ed5a7e9213bf5047f5b12c360c33387b1bc36cf79ddbff0a3a40121c";
                };
              };
            };
            # Unpatched nixpkgs regression breaks fixupPhase for any
            # multi-output derivation without bin/include/lib outputs and no
            # explicit propagatedBuildOutputs (bash word-splitting vs. array
            # handling bug in multiple-outputs.sh's _multioutPropagateDev).
            # Remove once upstream fixes pkgs/build-support/setup-hooks/multiple-outputs.sh.
            regclient = prev.regclient.overrideAttrs (_old: {
              propagatedBuildOutputs = "";
            });
          })
        ];
      };
    in
    {
      homeConfigurations = {
        "dseymour@falcon" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = { inherit nixgl sops-nix; };

          modules = [
            ./modules/falcon
            ./modules/common
            nix-flatpak.homeManagerModules.nix-flatpak
            sops-nix.homeManagerModules.sops
          ];
        };

        "dseymour@beefcake" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = { inherit nixgl sops-nix; };

          modules = [
            ./modules/beefcake
            ./modules/common
            nix-flatpak.homeManagerModules.nix-flatpak
            sops-nix.homeManagerModules.sops
          ];
        };

        "dseymour@iron-man" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = { inherit nixgl sops-nix; };

          modules = [
            ./modules/iron-man
            ./modules/common
            nix-flatpak.homeManagerModules.nix-flatpak
            sops-nix.homeManagerModules.sops
          ];
        };
      };
    };
}
