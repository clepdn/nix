{ pkgs, lib, ... }:
let
  mcefLibraries = with pkgs; [
    stdenv.cc.cc.lib
    nspr
    nss
    glib
    dbus
    atk
    at-spi2-atk
    at-spi2-core
    cups
    libgbm
    libxkbcommon
    expat
    cairo
    pango
    systemd
    alsa-lib
    fontconfig
    freetype
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
  ];
  prismlauncherWithMcef = pkgs.prismlauncher.override {
    additionalLibs = mcefLibraries;
  };
in
{
  imports = [ ./default.nix ];

  # MCEF/JCEF ships an unpatched Chromium shared library. nix-ld supports helper
  # executables, while the launcher supplies the library path for JVM dlopen().
  programs.nix-ld.libraries = mcefLibraries;

  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "prismlauncher";
      paths = [ prismlauncherWithMcef ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        # Prism's inner wrapper overwrites inherited LD_LIBRARY_PATH. Adding
        # these libraries there ensures its Java child inherits them.
        wrapProgram "$out/bin/prismlauncher" \
          --set XKB_CONFIG_ROOT "${pkgs.xkeyboard-config}/share/X11/xkb"
      '';
      meta.mainProgram = "prismlauncher";
    })
  ];
}
