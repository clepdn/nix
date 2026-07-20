{
  lib, stdenv, fetchurl, autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  pname = "omp";
  version = "17.0.5";

  src =
    let
      platformMap = {
        "x86_64-linux" = "linux-x64";
        "aarch64-linux" = "linux-arm64";
      };

      platform = platformMap.${stdenv.hostPlatform.system};

      hashes = {
        "x86_64-linux" = "sha256-MZ0Iq45fuAxz9zSQfV9Hqou9TqMfehm6z4YRxauibDE=";
        "aarch64-linux" = "sha256-VVBGuVuI0VNP9MqF6lgU74nLNfqKpK87Dj0zEGLanCw=";
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

  nativeBuildInputs = [ autoPatchelfHook ];

  # Bun-compiled standalone binary; only links against glibc, but keep
  # libstdc++/libgcc available in case it dlopens them at runtime.
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/omp"
    runHook postInstall
  '';

  meta = with lib; {
    description = "oh-my-pi (omp): AI coding agent for the terminal";
    homepage = "https://omp.sh";
    license = licenses.mit;
    mainProgram = "omp";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
