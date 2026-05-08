{ lib, pkgs, config, ... }:
let
  cfg = config.myConfig.vllm;
  extraArgsStr = lib.optionalString (cfg.extraArgs != [ ]) " ${lib.concatStringsSep " " cfg.extraArgs}";
  baseURL = "http://${cfg.host}:${toString cfg.port}/v1";
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

    toolCallParser = lib.mkOption {
      type = lib.types.str;
      default = "hermes";
      example = "llama3_json";
      description = ''
        vLLM tool call parser. Common values:
          hermes       — Qwen, Nous Hermes
          mistral      — Mistral / Mixtral
          llama3_json  — Llama 3
          granite      — IBM Granite
      '';
    };

    opencode = {
      enable = lib.mkEnableOption "OpenCode AI coding assistant configured against the local vLLM backend";
    };

    hfTokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/secrets/hf-token";
      description = ''
        Path to a file containing the HuggingFace token in KEY=VALUE format
        for systemd EnvironmentFile. The token is never written to the Nix
        store or the git-tracked config.

        Create it with:
          install -m 600 /dev/null <path>
          echo "HF_TOKEN=hf_..." > <path>
      '';
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

    home.packages = [ pkgs.vllm ]
      ++ lib.optionals cfg.opencode.enable [ pkgs.opencode ];

    systemd.user.services.vllm = {
      Unit = {
        Description = "vLLM OpenAI-compatible inference server";
        After = [ "network.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.vllm}/bin/vllm serve ${cfg.model} --host ${cfg.host} --port ${toString cfg.port} --kv_offloading_backend native --kv_offloading_size ${toString cfg.kvCacheSize} --enable-auto-tool-choice --tool-call-parser ${cfg.toolCallParser}${extraArgsStr}";
        Restart = "on-failure";
        RestartSec = "10s";
        Environment = [ "HF_HOME=%h/.cache/huggingface" ];
        EnvironmentFile = lib.mkIf (cfg.hfTokenFile != null) [ cfg.hfTokenFile ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    xdg.configFile."opencode/opencode.json" = lib.mkIf cfg.opencode.enable {
      text = builtins.toJSON {
        provider.vllm = {
          npm = "@ai-sdk/openai-compatible";
          name = "vLLM (local)";
          options.baseURL = baseURL;
          models."${cfg.model}".name = cfg.model;
        };
        model = "vllm/${cfg.model}";
      };
    };

    home.file.".local/share/opencode/auth.json" = lib.mkIf cfg.opencode.enable {
      text = builtins.toJSON {
        vllm = {
          type = "api";
          key = "sk-local";
        };
      };
    };
  };
}
