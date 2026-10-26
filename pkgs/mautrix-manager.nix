{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libdrm,
  libglvnd,
  libgbm,
  libxkbcommon,
  nspr,
  nss,
  openssl,
  pango,
  systemd,
  vulkan-loader,
  xorg,
}:
stdenv.mkDerivation rec {
  pname = "mautrix-manager";
  version = "0.2.1";

  src = fetchurl {
    url = "https://github.com/mautrix/manager/releases/download/v${version}/mautrix-manager_${version}_amd64.deb";
    hash = "sha256-lMyp/+IIdSGgQvivxlbBQD3Mea+YCs0ilCCCmzZ+of0=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libgbm
    libxkbcommon
    nspr
    nss
    openssl
    pango
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
  ];

  # Chromium dlopens these at runtime, so autoPatchelf cannot find them.
  runtimeDependencies = [
    libglvnd
    systemd
    vulkan-loader
  ];

  # The sandbox rejects the setuid bit on chrome-sandbox, so skip permissions.
  unpackPhase = "dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/lib $out/share
    cp -r usr/lib/mautrix-manager $out/lib/
    ln -s $out/lib/mautrix-manager/mautrix-manager $out/bin/mautrix-manager
    cp -r usr/share/applications usr/share/pixmaps $out/share/
    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeDependencies})
  '';

  meta = {
    description = "Electron app for logging in to mautrix bridges";
    homepage = "https://github.com/mautrix/manager";
    platforms = [ "x86_64-linux" ];
    mainProgram = "mautrix-manager";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
