{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.features.cloud.enable = lib.mkEnableOption "Cloud provider and infrastructure tools";

  config = lib.mkIf config.features.cloud.enable {
    home.packages = with pkgs; [
      awscli2
      aws-iam-authenticator
      tenv
      terraform-docs
      tflint
      tfsec
      (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
    ];
    home.sessionVariables.TENV_AUTO_INSTALL = "true";
  };
}
