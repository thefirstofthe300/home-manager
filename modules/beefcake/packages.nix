{ pkgs, ... }: {
  home.packages = with pkgs; [
    tenv
    terraform-docs
    tflint
    tfsec
    aws-iam-authenticator
    istioctl
    clusterctl
    helm-docs
    kind
    minikube
  ];
}
