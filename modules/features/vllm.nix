{ lib, pkgs, config, ... }:
let
  cfg = config.myConfig.vllm;
  extraArgsStr = lib.optionalString (cfg.extraArgs != [ ]) " ${lib.concatStringsSep " " cfg.extraArgs}";
in {
  options.myConfig.vllm = {
    enable = lib.mkEnableOption "vLLM OpenAI-compatible inference server";

    model = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "meta-llama/Llama-3.1-8B-Instruct";
      description = "HuggingFace model identifier or local path to serve";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address to bind the server";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Port to listen on";
    };

    kvCacheSize = lib.mkOption {
      type = lib.types.number;
      default = 4;
      description = "CPU KV cache space in GiB per GPU for KV cache offloading (0 to disable)";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional arguments passed to vllm serve";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = cfg.model != "";
      message = "myConfig.vllm.model must be set to a HuggingFace model ID when vLLM is enabled";
    }];

    home.packages = [ pkgs.vllm ];

    systemd.user.services.vllm = {
      Unit = {
        Description = "vLLM OpenAI-compatible inference server";
        After = [ "network.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.vllm}/bin/vllm serve ${cfg.model} --host ${cfg.host} --port ${toString cfg.port} --kv_offloading_backend native --kv_offloading_size ${toString cfg.kvCacheSize}${extraArgsStr}";
        Restart = "on-failure";
        RestartSec = "10s";
        Environment = [ "HF_HOME=%h/.cache/huggingface" ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
