{ ... }:
{
  features.cloud.enable = true;
  features.development.enable = true;
  features.sbom.enable = true;
  features.kubernetes.enable = true;

  nix.gc.automatic = true;

  programs = {
    jqp.enable = true;
    git = {
      enable = true;
      signing = {
        format = null;
      };
      includes = [
        {
          contents = {
            user = {
              name = "Danny Seymour";
              email = "danny.seymour@gremlin.com";
              signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBLs1zuIf732rfBMxwN6ly3bWM+xNqPiw5ahLpTvVj7k";
            };
            gpg.format = "ssh";
            commit.gpgSign = true;
            signing.signByDefault = true;
          };
        }
      ];
    };
  };
}
