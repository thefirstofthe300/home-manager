{ ... }: {
  imports = [
    ./kubernetes.nix
    ./cloud.nix
    ./development.nix
    ./sbom.nix
    ./local-llm.nix
  ];
}
