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

  # Robrix isn't packaged in nixpkgs, and building it from source hits a nixpkgs
  # Cargo-vendoring bug (a nested pre-vendored `libs/rapier/vendor/*` directory inside
  # the makepad-widgets git dependency has committed `.cargo-checksum.json` files that
  # the vendoring tool can't overwrite). So this wraps upstream's official prebuilt
  # x86_64 AppImage release instead, via appimageTools.
  robrixVersion = "1.0.0-alpha.2";
  robrixSrc = pkgs.fetchurl {
    url = "https://github.com/project-robius/robrix/releases/download/v${robrixVersion}/robrix-${robrixVersion}-x86_64.AppImage";
    hash = "sha256-nYcCJtDcUfp71IFs86vZ9HiXt/29ycyMopyHsYWu8dA=";
  };
  robrixAppimageContents = pkgs.appimageTools.extract {
    pname = "robrix";
    version = robrixVersion;
    src = robrixSrc;
  };
  robrixUnwrapped = pkgs.appimageTools.wrapType2 {
    pname = "robrix";
    version = robrixVersion;
    src = robrixSrc;

    extraPkgs = pkgs: with pkgs; [
      openssl
      sqlite
      alsa-lib
      libpulseaudio
      dbus
      wayland
      libxkbcommon
      libx11
      libxcursor
      libglvnd
      fontconfig
      mesa
    ];

    extraInstallCommands = ''
      install -Dm444 ${robrixAppimageContents}/usr/share/applications/robrix.desktop -t $out/share/applications
      cp -r ${robrixAppimageContents}/usr/share/icons $out/share/
    '';

    # The AppImage bundles its own (older) libwayland-client.so.0, which is ABI-incompatible
    # with the Nix-provided mesa EGL Wayland platform code: eglGetPlatformDisplayEXT() returns
    # EGL_NO_DISPLAY when the bundled copy is loaded. Shadow it with the Nix-provided one.
    extraBwrapArgs = [
      "--ro-bind ${pkgs.wayland}/lib/libwayland-client.so.0 ${robrixAppimageContents}/usr/lib/libwayland-client.so.0"
    ];
  };
  robrix = pkgs.runCommand "robrix-${robrixVersion}"
    {
      nativeBuildInputs = [ pkgs.makeWrapper ];
      meta = with lib; {
        description = "A powerful multi-platform Matrix chat client written from scratch in Rust";
        homepage = "https://github.com/project-robius/robrix";
        license = licenses.mit;
        platforms = [ "x86_64-linux" ];
        mainProgram = "robrix";
      };
    }
    ''
      mkdir -p $out/bin $out/share
      cp -r ${robrixUnwrapped}/share/. $out/share/
      makeWrapper ${robrixUnwrapped}/bin/robrix $out/bin/robrix \
        --set __EGL_VENDOR_LIBRARY_FILENAMES "/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json:${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
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

  sops.secrets.gremlin-api-key = {
    sopsFile = ../../secrets/common.yaml;
  };

  features.vllm = {
    enable = false;
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
        version = "595.91.07";
        sha256 = "sha256-yiPIjdJLB6GRZE4eEc+3vN11NzBXSa9A+YABiwleYxM=";
      };
    };
  };

  features.development = {
    gremlinSkillsPath = "/home/dseymour/workspace/github.com/gremlin/gremlin-ai-skills";
    jiraEmail = "danny.seymour@gremlin.com";
    workSkills = [ "investigate-alert" "eng-private-edition" ];
    mcp = {
      observe = true;
      jira = true;
      circleci = true;
    };
  };

  programs.mcp.servers = {
    gremlin = {
      command = lib.getExe (
        pkgs.writeShellApplication {
          name = "gremlin-mcp";
          runtimeInputs = [ pkgs.nodejs ];
          text = ''
            GREMLIN_API_KEY=$(cat ${lib.escapeShellArg config.sops.secrets.gremlin-api-key.path})
            export GREMLIN_API_KEY
            exec npx -y @gremlin/mcp-server "$@"
          '';
        }
      );
    };
  };

  home = {
    packages = with pkgs; [
      jetbrains.idea
      cmake
      clang
      llvmPackages.libclang.lib
      # devfiler
      robrix
      pi-coding-agent
      python314Packages.huggingface-hub
      packer
      trivy
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
