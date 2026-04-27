{ lib, pkgs, config, ... }:
let
  cfg = config.myConfig.localLlm;
in {
  options.myConfig.localLlm = {
    enable = lib.mkEnableOption "Local LLM stack (Ollama)";
    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "gemma4:e2b" ];
      description = "Ollama models to pull on activation";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      acceleration = "cuda";
      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "256000";
      };
    };
  };
}
