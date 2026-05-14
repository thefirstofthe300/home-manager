{
  pkgs,
  lib,
  config,
  ...
}:
let
  devfilerBase = pkgs.rustPlatform.buildRustPackage {
    pname = "devfiler";
    version = "0.15.0";

    src = pkgs.fetchgit {
      url = "https://github.com/elastic/devfiler";
      rev = "81aa1af2ba176ec590f24310e333888abb479894";
      fetchSubmodules = true;
      hash = "sha256-ReMn5fe4x80DEM4fOfDMdDQoFWyQEypKzkivCVaRNjs=";
    };

    cargoHash = "sha256-41Ay9nNALfTQEe8R2enaVlMD00PI3hRwEGIb5X7KzGM=";

    buildNoDefaultFeatures = true;
    buildFeatures = [
      "render-opengl"
      "automagic-symbols"
      "allow-dev-mode"
    ];

    nativeBuildInputs = with pkgs; [
      pkg-config
      cmake
      clang
      protobuf
      makeWrapper
    ];

    buildInputs = with pkgs; [
      llvmPackages.libclang.lib
      openssl
      libGL
      wayland
      libxkbcommon
      libx11
      libxcursor
      libxi
      libxrandr
    ];

    env = {
      LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
      # RocksDB headers omit <cstdint> includes, which GCC 15 requires explicitly
      CXXFLAGS = "-include cstdint";
    };

    postInstall = ''
      wrapProgram $out/bin/devfiler \
        --prefix LD_LIBRARY_PATH : ${
          lib.makeLibraryPath (
            with pkgs;
            [
              libxkbcommon
              wayland
              libx11
              libxcursor
              libxi
              libxrandr
            ]
          )
        }
    '';
  };

  # Mirror what nixGLNvidia does, using the libs targets.genericLinux.gpu.nvidia
  # already places in /run/opengl-driver.
  devfiler = pkgs.writeShellScriptBin "devfiler" ''
    export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json:/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json''${__EGL_VENDOR_LIBRARY_FILENAMES:+:$__EGL_VENDOR_LIBRARY_FILENAMES}
    export LD_LIBRARY_PATH=${pkgs.libglvnd}/lib:/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    exec ${devfilerBase}/bin/devfiler "$@"
  '';
in
{
  imports = [ ../profiles/work.nix ];

  features.cloud.enable = true;
  features.development.enable = true;
  features.kubernetes.enable = true;
  features.sbom.enable = true;

  sops.secrets.hf-token = {
    sopsFile = ../../secrets/common.yaml;
  };

  features.vllm = {
    enable = true;
    model = "google/gemma-4-E2B";
    toolCallParser = "pythonic";
    hfTokenFile = config.sops.secrets.hf-token.path;
    opencode.enable = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
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
          mkDriver =
            driverArgs:
            let
              drv = prev.linuxPackages.nvidiaPackages.mkDriver driverArgs;
            in
            drv
            // {
              override = overrideArgs: drv.override (builtins.removeAttrs overrideArgs [ "kernel" ]);
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

  features.development.gremlinSkillsPath = "/home/dseymour/workspace/github.com/gremlin/gremlin-ai-skills";
  features.development.jiraEmail = "danny.seymour@gremlin.com";

  home = {
    packages = with pkgs; [
      jetbrains.idea
      cmake
      clang
      llvmPackages.libclang.lib
      devfiler
    ];

    sessionVariables = {
      LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    };
  };

  xdg.autostart.entries = [
    "/home/dseymour/.local/share/flatpak/exports/share/applications/im.riot.Riot.desktop"
  ];

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
