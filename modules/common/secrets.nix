{
  lib,
  config,
  ...
}:
{
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  home.activation.fetchAgeKey = lib.hm.dag.entryBefore [ "sops" ] ''
    keyDir="$HOME/.config/sops/age"
    keyFile="$keyDir/keys.txt"
    $DRY_RUN_CMD mkdir -p "$keyDir"
    if ! [ -s "$keyFile" ]; then
      $VERBOSE_ECHO "Fetching sops age key from 1Password..."
      tmpKey="$(mktemp)"
      if XDG_RUNTIME_DIR="/run/user/$(id -u)" \
           op read \
           "op://Private/SOPS Age Key/private key" \
           > "$tmpKey" 2>&1; then
        mv "$tmpKey" "$keyFile"
        $DRY_RUN_CMD chmod 600 "$keyFile"
      else
        rm -f "$tmpKey"
        $VERBOSE_ECHO "Warning: could not fetch sops age key from 1Password. Populate $keyFile manually."
      fi
    fi
  '';
}
