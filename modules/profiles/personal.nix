{ ... }: {
  programs.git = {
    enable = true;
    includes = [{
      contents = {
        user = {
          name = "Danny Seymour";
          email = "danny@seymour.family";
          signingKey =
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBLs1zuIf732rfBMxwN6ly3bWM+xNqPiw5ahLpTvVj7k";
        };
        gpg.format = "ssh";
        commit.gpgSign = true;
      };
    }];
  };
}
