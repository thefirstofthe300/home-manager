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
            claude-desktop = claude-desktop-debian.packages.${system}.claude-desktop;
            # Pinned ahead of nixpkgs-unstable, which lags the upstream
            # claude-code release. Drop once nixpkgs reaches this version.
            # Checksum is of linux-x64/claude.zst under
            # https://downloads.claude.ai/claude-code-releases/<version>/
            claude-code = prev.claude-code.override {
              manifest = {
                version = "2.1.293";
                platforms.linux-x64 = {
                  binary = "claude.zst";
                  checksum = "25786da347c30641dc6c50733d090d77cb540f105a61af7e9895b56e39fe16a5";
                };
              };
            };
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
