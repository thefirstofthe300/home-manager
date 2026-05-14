{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.features.kubernetes.enable = lib.mkEnableOption "Kubernetes development tools";

  config = lib.mkIf config.features.kubernetes.enable {
    home.packages = with pkgs; [
      kubectl
      kubernetes-helm
      fluxcd
      kind
      minikube
      istioctl
      clusterctl
      kubeseal
      velero
      talosctl
      helm-docs
      tilt
    ];
  };
}
