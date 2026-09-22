{
  description = "Home Manager configuration for Daniel Seymour";

  nixConfig = {
    extra-substituters = [ 
"https://cache.nixos-cuda.org" 
"https://cache.flox.dev"
];
    extra-trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];
  };

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
    flox = {
      url = "github:flox/flox/latest";
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
      flox,
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
            flox = flox.packages.${system}.default;
            serena = serena.packages.${system}.serena;
            claude-desktop = claude-desktop-debian.packages.${system}.claude-desktop;
            # nixpkgs-unstable lags the upstream claude-code release by a few
            # days; override to the latest release until nixpkgs catches up.
            # Bump version/checksum from https://downloads.claude.ai/claude-code-releases/latest
            claude-code = prev.claude-code.override {
              manifest = {
                version = "2.1.280";
                platforms.linux-x64 = {
                  binary = "claude.zst";
                  checksum = "27910e2ae704d8f2e8024897d8fdf1e7710807baf4f6982c0e3797c058315384";
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
