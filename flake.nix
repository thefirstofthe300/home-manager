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
  };

  outputs = { nixpkgs, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations = {
        "dseymour@falcon" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = { inherit nixgl; };

          modules = [ ./modules/falcon ./modules/common ];
        };

        "dseymour@beefcake" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = { inherit nixgl; };

          modules = [
            ./modules/beefcake.nix
            ./modules/common/terminal.nix
            ./modules/common/zsh.nix
          ];
        };
      };
    };
}
