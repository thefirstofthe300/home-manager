{ lib, pkgs, config, ... }:
{
  options.myConfig.kubernetes.enable =
    lib.mkEnableOption "Kubernetes development tools";

  config = lib.mkIf config.myConfig.kubernetes.enable {
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
