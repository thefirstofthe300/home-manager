{ ... }: {
  myConfig.cloud.enable = true;
  myConfig.development.enable = true;
  myConfig.sbom.enable = true;
  myConfig.kubernetes.enable = true;

  nix.gc.automatic = true;

  programs = {
    jqp.enable = true;
    git = {
      enable = true;
      includes = [{
        contents = {
          user = {
            name = "Danny Seymour";
            email = "danny.seymour@gremlin.com";
            signingKey =
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBLs1zuIf732rfBMxwN6ly3bWM+xNqPiw5ahLpTvVj7k";
          };
          gpg.format = "ssh";
          commit.gpgSign = true;
          signing.signByDefault = true;
        };
      }];
    };
  };
}
