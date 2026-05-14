{
  lib,
  config,
  ...
}:
let
  cfg = config.features.localLlm;
in
{
  options.features.localLlm = {
    enable = lib.mkEnableOption "Local LLM stack (Ollama)";

    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "gemma4:e2b" ];
      description = "Ollama models to pull on activation";
    };

    acceleration = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [
        "cuda"
        "rocm"
        "metal"
      ]);
      default = null;
      description = "GPU acceleration backend for Ollama. Set to null for CPU-only inference.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      acceleration = cfg.acceleration;
      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "256000";
      };
    };
  };
}
