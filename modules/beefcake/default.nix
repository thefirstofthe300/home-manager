{ pkgs, ... }: {
  imports = [ ../profiles/work.nix ];

  myConfig.cloud.enable = true;
  myConfig.development.enable = true;
  myConfig.kubernetes.enable = true;
  myConfig.sbom.enable = true;

  myConfig.vllm = {
    enable = true;
    model = "Qwen/Qwen2.5-7B-Instruct";
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = (pkg: true);
    nvidia.acceptLicense = true;
    cudaSupport = true;
  };

  # Workaround for home-manager PR #9240: targets.genericLinux.gpu calls
  # .override { kernel = null; } but nixpkgs removed that parameter.
  # Strip it before forwarding to the real override.
  nixpkgs.overlays = [
    (final: prev: {
      linuxPackages = prev.linuxPackages // {
        nvidiaPackages = prev.linuxPackages.nvidiaPackages // {
          mkDriver = driverArgs:
            let
              drv = prev.linuxPackages.nvidiaPackages.mkDriver driverArgs;
            in
              drv // {
                override = overrideArgs:
                  drv.override (builtins.removeAttrs overrideArgs [ "kernel" ]);
              };
        };
      };
    })
  ];

  targets.genericLinux = {
    gpu = {
      enable = true;
      nvidia = {
        enable = true;
        version = "595.71.05";
        sha256 = "sha256-NiA7iWC35JyKQva6H1hjzeNKBek9KyS3mK8G3YRva4I=";
      };
    };
  };

  home = {
    username = "dseymour";
    homeDirectory = "/home/dseymour";
    stateVersion = "24.05";

    packages = with pkgs; [
      nil
      nixfmt
      jetbrains.idea
    ];
  };

  programs = {
    home-manager = {
      enable = true;
    };
  };

  services = {
    flatpak = {
      enable = true;
      update = {
        auto = {
          enable = true;
          onCalendar = "daily";
        };
      };
      packages = [
        "com.slack.Slack"
        "com.spotify.Client"
        "com.github.tchx84.Flatseal"
        "net.nokyan.Resources"
        "im.riot.Riot"
        "com.fastmail.Fastmail"
      ];
    };
  };
}
