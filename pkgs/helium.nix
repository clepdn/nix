{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, alsa-lib
, mesa
, nss
, nspr
, libx11
, libxcomposite
, libxdamage
, libxext
, libxfixes
, libxrandr
, libxcb
, libdrm
, libxkbcommon
, expat
, cups
, dbus
, at-spi2-atk
, pango
, cairo
, glib
, gtk3
}:
stdenv.mkDerivation rec {
  pname = "helium";
  version = "0.10.9.1";

  src =
    let
      platformMap = {
        "x86_64-linux" = "x86_64_linux";
        "aarch64-linux" = "arm64_linux";
      };

      platform = platformMap.${stdenv.hostPlatform.system};

      hashes = {
        "x86_64-linux" = "sha256-ob1iSE+4IrsHthEpEypgSkZs2LT4H2YXknjD1FKn3sc=";
        "aarch64-linux" = lib.fakeHash;
      };

      hash = hashes.${stdenv.hostPlatform.system};
    in
    fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-${platform}.tar.xz";
      inherit hash;
    };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    alsa-lib
    mesa
    nss
    nspr
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    libdrm
    libxkbcommon
    expat
    cups
    dbus
    at-spi2-atk
    pango
    cairo
    glib
    gtk3
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    mkdir -p "$out/share/lib/helium"

    cp -r . "$out/share/lib/helium/"
    ln -s "$out/share/lib/helium/helium" "$out/bin/helium"

    cp -r locales "$out/share/lib/helium/"
    cp -r usr/share "$out/" 2>/dev/null || true

    runHook postInstall
  '';

  meta = {
    description = "Private, fast, and honest web browser based on Chromium";
    homepage = "https://github.com/imputnet/helium-chromium";
    changelog = "https://github.com/imputnet/helium-linux/releases/tag/${version}";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    license = lib.licenses.gpl3;
    mainProgram = "helium";
  };
}
