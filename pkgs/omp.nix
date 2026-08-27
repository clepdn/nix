{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  libpulseaudio,
}:
stdenv.mkDerivation rec {
  pname = "omp";
  version = "18.0.4";

  src =
    let
      platformMap = {
        "x86_64-linux" = "linux-x64";
        "aarch64-linux" = "linux-arm64";
      };

      platform = platformMap.${stdenv.hostPlatform.system};

      hashes = {
        "x86_64-linux" = "sha256-lOxC0X1xl1o4HiAzW7PABaf9fuwZsxk1jfbSLyjhazc=";
        "aarch64-linux" = "sha256-8rfIoBloHt4xSsFlEAwcW1zUkAE5B1lI2oCcAEvsXOc=";
      };

      hash = hashes.${stdenv.hostPlatform.system};
    in
    fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-${platform}";
      inherit hash;
    };

  dontUnpack = true;

  # Bun appends its module bundle after the ELF; stripping rewrites the ELF and
  # discards that trailing payload, degrading omp into the plain Bun runtime.
  dontStrip = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  # Bun dlopens the playback backends and the TTS runtime dlopens libstdc++.
  # Patching this executable's RPATH corrupts its appended JavaScript bundle,
  # so supply every dynamic runtime library from a wrapper.
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/omp"
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram "$out/bin/omp" \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          alsa-lib
          libpulseaudio
          stdenv.cc.cc.lib
        ]
      }"
  '';

  meta = with lib; {
    description = "oh-my-pi (omp): AI coding agent for the terminal";
    homepage = "https://omp.sh";
    license = licenses.mit;
    mainProgram = "omp";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
