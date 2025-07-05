{
  description = "Home Manager configuration of dseymour";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl.url = "github:nix-community/nixGL";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = { nixpkgs, home-manager, nixgl, nix-flatpak, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations = {
        "dseymour@falcon" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = { inherit nixgl; };

          modules = [
            ./modules/falcon
            ./modules/common
            nix-flatpak.homeManagerModules.nix-flatpak
          ];
        };

        "dseymour@beefcake" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = { inherit nixgl; };

          modules = [
            ./modules/beefcake
            ./modules/common
            nix-flatpak.homeManagerModules.nix-flatpak
          ];
        };
      };
    };
}
