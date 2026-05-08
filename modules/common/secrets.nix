{ pkgs, lib, config, ... }: {
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  home.activation.fetchAgeKey = lib.hm.dag.entryBefore [ "sops" ] ''
    keyDir="$HOME/.config/sops/age"
    keyFile="$keyDir/keys.txt"
    $DRY_RUN_CMD mkdir -p "$keyDir"
    if ! [ -s "$keyFile" ]; then
      $VERBOSE_ECHO "Fetching sops age key from 1Password..."
      ${pkgs._1password}/bin/op read \
        "op://Private/sops age key (beefcake)/private key" \
        > "$keyFile"
      $DRY_RUN_CMD chmod 600 "$keyFile"
    fi
  '';
}
