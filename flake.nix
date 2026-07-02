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
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (_: _: {
            flox = flox.packages.${system}.default;
            serena = serena.packages.${system}.serena;
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
