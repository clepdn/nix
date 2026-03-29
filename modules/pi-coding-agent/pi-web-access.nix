{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage {
  pname = "pi-web-access";
  version = "0.10.4-unstable-2026-03-27";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "37d70019eebb4f3479f58d6ed8c107660f60bc6d";
    hash = "sha256-8rxSNJrxk8wPEpnQUuxwvXywkH1e3RecZGYuTRW7wQc=";
  };

  npmDepsHash = "sha256-zau3eaJoa8pE3A5COXwyTLSesoePgYqrnRCg3SMSarw=";

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    cp -r . $out
    runHook postInstall
  '';

  meta = {
    description = "Web search, URL fetching, GitHub repo cloning, PDF extraction, YouTube video understanding, and local video analysis for Pi coding agent";
    homepage = "https://github.com/nicobailon/pi-web-access";
    license = lib.licenses.mit;
  };
}
