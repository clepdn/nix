{ pkgs, lib, claude-code, ... }:

pkgs.buildNpmPackage {
  pname = "happy-cli";
  version = "1.1.7";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/happy/-/happy-1.1.7.tgz";
    hash = "sha512-CDz2s79ggcj/aLjWuOay8x4xz8Z5niit1rXbz0ZoRVaJ+Zek3O8uNi1uPcvJ5HjZyxI4H9C6CXBqhEytfIj6OA==";
  };

  # npm tarball extracts into a `package/` subdirectory
  sourceRoot = "package";

  npmDepsHash = "sha256-IZqROHkR3o0YxUWq8/Gq8b5z1vI8nkYLzpEiZyOICVo=";

  postPatch = ''
    cp ${./happy-cli-package-lock.json} package-lock.json
  '';

  npmInstallFlags = [ "--legacy-peer-deps" ];
  npmFlags = [ "--ignore-scripts" ];

  dontNpmBuild = true;
  dontNpmPrune = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  postInstall = ''
    # Stub the optional platform-specific package so claude-agent-sdk can find Claude Code
    mkdir -p $out/lib/node_modules/happy/node_modules/@anthropic-ai/claude-agent-sdk-linux-x64-musl
    ln -sf ${claude-code}/bin/claude \
      $out/lib/node_modules/happy/node_modules/@anthropic-ai/claude-agent-sdk-linux-x64-musl/claude

    wrapProgram $out/bin/happy \
      --prefix PATH : ${pkgs.nodejs}/bin \
      --set HAPPY_CLAUDE_PATH ${claude-code}/lib/node_modules/@anthropic-ai/claude-code/cli.js
    wrapProgram $out/bin/happy-mcp \
      --prefix PATH : ${pkgs.nodejs}/bin
  '';

  meta = {
    description = "Mobile and Web client for Claude Code and Codex";
    homepage = "https://happy.engineering";
    license = lib.licenses.mit;
    mainProgram = "happy";
  };
}
